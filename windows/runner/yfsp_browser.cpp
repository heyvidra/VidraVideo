// Windows WebView2 port of macOS's YfspBrowser (see MainFlutterWindow.swift).
//
// One process-wide WebView2 carries yfsp's requests: hidden off-screen while it
// fetches, shown as a window while the user passes the Cloudflare challenge. It
// speaks the same `vidra/yfsp_browser` channel (solve/keys/fetch) so the Dart
// side is identical to macOS.
//
// WebView2 is single-threaded: its async callbacks land on the UI thread, the
// same thread Flutter delivers platform-channel calls on, so no marshalling is
// needed — operations are just chained through completion handlers and
// serialised through one queue (one navigation at a time).
//
// NOTE (untested on macOS host): this file could only be written, not compiled,
// from the dev machine. The logic mirrors the proven Swift path; expect to fix
// small Win32/WebView2 signature details on the first Windows build.

#include "yfsp_browser.h"

#include <windows.h>
#include <wrl.h>
#include <WebView2.h>

#include <flutter/method_channel.h>
#include <flutter/method_result.h>
#include <flutter/standard_method_codec.h>

#include <functional>
#include <memory>
#include <optional>
#include <queue>
#include <string>
#include <utility>
#include <vector>

using Microsoft::WRL::Callback;
using Microsoft::WRL::ComPtr;

namespace {

std::wstring Utf8ToWide(const std::string& s) {
  if (s.empty()) return L"";
  int n = MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), nullptr, 0);
  std::wstring w(n, 0);
  MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), w.data(), n);
  return w;
}

std::string WideToUtf8(const std::wstring& w) {
  if (w.empty()) return "";
  int n = WideCharToMultiByte(CP_UTF8, 0, w.data(), (int)w.size(), nullptr, 0,
                              nullptr, nullptr);
  std::string s(n, 0);
  WideCharToMultiByte(CP_UTF8, 0, w.data(), (int)w.size(), s.data(), n, nullptr,
                      nullptr);
  return s;
}

// ExecuteScript hands back the result JSON-ENCODED. Every script here returns a
// JS string, so the raw result is that string wrapped in quotes and escaped.
// Decode one layer to recover it. A non-string result (e.g. "null") yields "".
std::wstring JsonUnescape(const std::wstring& in) {
  if (in.size() < 2 || in.front() != L'"') return L"";
  std::wstring out;
  for (size_t i = 1; i + 1 < in.size(); ++i) {
    wchar_t c = in[i];
    if (c != L'\\') {
      out.push_back(c);
      continue;
    }
    if (i + 1 >= in.size() - 1) break;
    wchar_t e = in[++i];
    switch (e) {
      case L'"': out.push_back(L'"'); break;
      case L'\\': out.push_back(L'\\'); break;
      case L'/': out.push_back(L'/'); break;
      case L'n': out.push_back(L'\n'); break;
      case L'r': out.push_back(L'\r'); break;
      case L't': out.push_back(L'\t'); break;
      case L'b': out.push_back(L'\b'); break;
      case L'f': out.push_back(L'\f'); break;
      case L'u': {
        if (i + 4 < in.size()) {
          wchar_t code = (wchar_t)std::wcstol(in.substr(i + 1, 4).c_str(),
                                              nullptr, 16);
          out.push_back(code);
          i += 4;
        }
        break;
      }
      default: out.push_back(e); break;
    }
  }
  return out;
}

// The page the webview parks on: its inline pConfig carries the signing keys,
// and being on www.yfsp.tv the API calls it hosts stay cross-origin (the shape
// that answers with JSON).
constexpr wchar_t kHomeUrl[] = L"https://www.yfsp.tv/list/drama";

// Reads pub + priv out of the key page's pConfig and returns them joined by a
// \x01 so no JSON re-parse is needed on the native side. Empty when absent.
constexpr wchar_t kReadKeysJs[] =
    L"(function(){var h=document.documentElement.outerHTML;"
    L"var m=h.match(/\"pConfig\"\\s*:\\s*\\{([^{}]*)\\}/);if(!m)return '';"
    L"var pub=(m[1].match(/\"publicKey\"\\s*:\\s*\"([^\"]+)\"/)||[])[1]||'';"
    L"var priv=(m[1].match(/\"privateKey\"\\s*:\\s*\\[\\s*\"([^\"]+)\"/)||[])[1]||'';"
    L"return pub+'\\u0001'+priv;})()";

constexpr wchar_t kReadBodyJs[] =
    L"document.body?document.body.innerText:document.documentElement.innerText";

constexpr wchar_t kPollJs[] =
    L"document.title+'\\u0001'+(document.body?document.body.innerText.slice(0,60):'')";

bool LooksLikeChallenge(const std::wstring& page) {
  auto has = [&](const wchar_t* s) { return page.find(s) != std::wstring::npos; };
  return page.empty() || has(L"Just a moment") || has(L"正在进行安全验证") ||
         has(L"请稍候") || has(L"Verifying") || has(L"Checking") ||
         has(L"challenge");
}

class YfspBrowser {
 public:
  static YfspBrowser& Instance() {
    static YfspBrowser instance;
    return instance;
  }

  // Serialises whole operations: only one navigation is ever in flight.
  void Enqueue(std::function<void(std::function<void()>)> op) {
    queue_.push(std::move(op));
    Pump();
  }

  void Solve(std::function<void(bool)> done) {
    solve_done_ = std::move(done);
    ShowSolveWindow();
    Navigate(challenge_url_, [](bool) {});
    solve_timer_ = SetTimer(host_, kSolveTimerId, 1000, nullptr);
  }

  void ReadKeys(
      std::function<void(std::optional<std::pair<std::string, std::string>>)>
          done) {
    Navigate(kHomeUrl, [this, done](bool ok) {
      if (!ok) {
        done(std::nullopt);
        return;
      }
      Eval(kReadKeysJs, [done](const std::wstring& raw) {
        auto sep = raw.find(L'\x01');
        if (sep == std::wstring::npos) {
          done(std::nullopt);
          return;
        }
        std::wstring pub = raw.substr(0, sep);
        std::wstring priv = raw.substr(sep + 1);
        if (pub.empty() || priv.empty()) {
          done(std::nullopt);
          return;
        }
        done(std::make_pair(WideToUtf8(pub), WideToUtf8(priv)));
      });
    });
  }

  // Navigates to the (signed) URL and reads the response document back — the
  // same shape a person gets typing the URL in, which returns the API JSON.
  void Fetch(const std::wstring& url,
             std::function<void(int, std::string, std::string)> done) {
    Navigate(url, [this, done](bool ok) {
      if (!ok) {
        done(-1, "", "navigation failed");
        return;
      }
      Eval(kReadBodyJs, [done](const std::wstring& body) {
        done(0, WideToUtf8(body), "");
      });
    });
  }

  // Called from the window proc.
  void OnTimer() { PollClearance(); }
  void OnCloseDuringSolve() { FinishSolve(false); }

 private:
  YfspBrowser() = default;

  static constexpr UINT_PTR kSolveTimerId = 1;

  // --- queue ---------------------------------------------------------------

  void Pump() {
    if (busy_ || queue_.empty()) return;
    if (!ready_) {
      EnsureWebView();  // resumes Pump() once the webview exists
      return;
    }
    busy_ = true;
    auto op = std::move(queue_.front());
    queue_.pop();
    op([this] {
      busy_ = false;
      Pump();
    });
  }

  // --- webview lifecycle ---------------------------------------------------

  void EnsureWebView() {
    if (creating_) return;
    creating_ = true;
    CreateHostWindow();
    // Per-user data folder next to the exe's %LOCALAPPDATA%; nullptr lets
    // WebView2 default it. A persistent store keeps a passed challenge across
    // restarts, matching macOS.
    CreateCoreWebView2EnvironmentWithOptions(
        nullptr, nullptr, nullptr,
        Callback<ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler>(
            [this](HRESULT, ICoreWebView2Environment* env) -> HRESULT {
              env->CreateCoreWebView2Controller(
                  host_,
                  Callback<
                      ICoreWebView2CreateCoreWebView2ControllerCompletedHandler>(
                      [this](HRESULT, ICoreWebView2Controller* controller)
                          -> HRESULT {
                        controller_ = controller;
                        controller_->get_CoreWebView2(&webview_);
                        controller_->put_IsVisible(TRUE);
                        RECT b;
                        GetClientRect(host_, &b);
                        controller_->put_Bounds(b);
                        ready_ = true;
                        Pump();
                        return S_OK;
                      })
                      .Get());
              return S_OK;
            })
            .Get());
  }

  void Navigate(const std::wstring& url, std::function<void(bool)> done) {
    nav_done_ = std::move(done);
    webview_->add_NavigationCompleted(
        Callback<ICoreWebView2NavigationCompletedEventHandler>(
            [this](ICoreWebView2*,
                   ICoreWebView2NavigationCompletedEventArgs* args) -> HRESULT {
              webview_->remove_NavigationCompleted(nav_token_);
              BOOL success = FALSE;
              if (args) args->get_IsSuccess(&success);
              auto cb = std::move(nav_done_);
              nav_done_ = nullptr;
              if (cb) cb(success == TRUE);
              return S_OK;
            })
            .Get(),
        &nav_token_);
    webview_->Navigate(url.c_str());
  }

  // Evaluates |js| (which must return a JS string) and hands back the decoded
  // string.
  void Eval(const std::wstring& js, std::function<void(std::wstring)> cb) {
    webview_->ExecuteScript(
        js.c_str(),
        Callback<ICoreWebView2ExecuteScriptCompletedHandler>(
            [cb](HRESULT, LPCWSTR result) -> HRESULT {
              cb(JsonUnescape(result ? std::wstring(result) : L""));
              return S_OK;
            })
            .Get());
  }

  // --- solve ---------------------------------------------------------------

  void PollClearance() {
    if (!solve_done_) return;
    Eval(kPollJs, [this](const std::wstring& page) {
      if (!solve_done_) return;
      if (LooksLikeChallenge(page)) return;
      // Passed — the real site is showing. Only the first detection fires.
      FinishSolve(true);
    });
  }

  void FinishSolve(bool ok) {
    if (solve_timer_) {
      KillTimer(host_, kSolveTimerId);
      solve_timer_ = 0;
    }
    auto cb = std::move(solve_done_);
    solve_done_ = nullptr;
    HideHostWindow();
    if (cb) cb(ok);
  }

  // --- host window ---------------------------------------------------------

  void CreateHostWindow() {
    if (host_) return;
    static const wchar_t* kClass = L"VidraYfspBrowserHost";
    WNDCLASSW wc = {};
    wc.lpfnWndProc = &YfspBrowser::WndProc;
    wc.hInstance = GetModuleHandleW(nullptr);
    wc.lpszClassName = kClass;
    RegisterClassW(&wc);
    // Off-screen (not hidden) so WebView2 is never throttled; solving moves it
    // on-screen.
    host_ = CreateWindowExW(0, kClass, L"人机验证",
                            WS_OVERLAPPEDWINDOW & ~WS_MINIMIZEBOX &
                                ~WS_MAXIMIZEBOX,
                            -4000, -4000, 480, 640, nullptr, nullptr,
                            wc.hInstance, nullptr);
    SetWindowLongPtrW(host_, GWLP_USERDATA, (LONG_PTR)this);
    ShowWindow(host_, SW_SHOWNOACTIVATE);
  }

  void ShowSolveWindow() {
    if (!host_) return;
    int sw = GetSystemMetrics(SM_CXSCREEN);
    int sh = GetSystemMetrics(SM_CYSCREEN);
    SetWindowPos(host_, HWND_TOP, (sw - 480) / 2, (sh - 640) / 2, 480, 640,
                 SWP_SHOWWINDOW);
    if (controller_) {
      RECT b;
      GetClientRect(host_, &b);
      controller_->put_Bounds(b);
    }
    SetForegroundWindow(host_);
  }

  void HideHostWindow() {
    if (host_) SetWindowPos(host_, nullptr, -4000, -4000, 480, 640,
                            SWP_NOZORDER | SWP_NOACTIVATE);
  }

  static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    auto* self = (YfspBrowser*)GetWindowLongPtrW(hwnd, GWLP_USERDATA);
    if (self) {
      switch (msg) {
        case WM_TIMER:
          self->OnTimer();
          return 0;
        case WM_SIZE:
          if (self->controller_) {
            RECT b;
            GetClientRect(hwnd, &b);
            self->controller_->put_Bounds(b);
          }
          return 0;
        case WM_CLOSE:
          // The user dismissed the challenge — a "no". Keep the window (and its
          // webview) alive for transport; just hide it.
          self->OnCloseDuringSolve();
          return 0;
      }
    }
    return DefWindowProcW(hwnd, msg, wp, lp);
  }

  HWND host_ = nullptr;
  ComPtr<ICoreWebView2Controller> controller_;
  ComPtr<ICoreWebView2> webview_;
  bool ready_ = false;
  bool creating_ = false;
  bool busy_ = false;
  std::queue<std::function<void(std::function<void()>)>> queue_;

  EventRegistrationToken nav_token_ = {};
  std::function<void(bool)> nav_done_;

  std::function<void(bool)> solve_done_;
  UINT_PTR solve_timer_ = 0;
  std::wstring challenge_url_ = L"https://www.yfsp.tv/list/drama";
};

}  // namespace

void RegisterYfspBrowser(flutter::FlutterEngine* engine) {
  auto channel =
      std::make_shared<flutter::MethodChannel<flutter::EncodableValue>>(
          engine->messenger(), "vidra/yfsp_browser",
          &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>> res(
            std::move(result));
        auto& browser = YfspBrowser::Instance();

        if (call.method_name() == "solve") {
          browser.Enqueue([res](std::function<void()> done) {
            YfspBrowser::Instance().Solve([res, done](bool ok) {
              res->Success(flutter::EncodableValue(ok));
              done();
            });
          });
        } else if (call.method_name() == "keys") {
          browser.Enqueue([res](std::function<void()> done) {
            YfspBrowser::Instance().ReadKeys(
                [res, done](
                    std::optional<std::pair<std::string, std::string>> keys) {
                  flutter::EncodableMap m;
                  if (keys) {
                    m[flutter::EncodableValue("pub")] =
                        flutter::EncodableValue(keys->first);
                    m[flutter::EncodableValue("priv")] =
                        flutter::EncodableValue(keys->second);
                  }
                  res->Success(flutter::EncodableValue(m));
                  done();
                });
          });
        } else if (call.method_name() == "fetch") {
          std::string url;
          if (const auto* args =
                  std::get_if<flutter::EncodableMap>(call.arguments())) {
            auto it = args->find(flutter::EncodableValue("url"));
            if (it != args->end()) {
              if (const auto* s = std::get_if<std::string>(&it->second)) {
                url = *s;
              }
            }
          }
          if (url.empty()) {
            res->Error("bad_args", "url missing");
            return;
          }
          std::wstring wurl = Utf8ToWide(url);
          browser.Enqueue([res, wurl](std::function<void()> done) {
            YfspBrowser::Instance().Fetch(
                wurl, [res, done](int status, std::string body,
                                  std::string err) {
                  flutter::EncodableMap m;
                  m[flutter::EncodableValue("status")] =
                      flutter::EncodableValue(status);
                  if (!body.empty()) {
                    m[flutter::EncodableValue("body")] =
                        flutter::EncodableValue(body);
                  }
                  if (!err.empty()) {
                    m[flutter::EncodableValue("error")] =
                        flutter::EncodableValue(err);
                  }
                  res->Success(flutter::EncodableValue(m));
                  done();
                });
          });
        } else {
          res->NotImplemented();
        }
      });

  // Each engine registers on its own messenger; hold every channel for the life
  // of the process so the handler stays wired.
  static std::vector<
      std::shared_ptr<flutter::MethodChannel<flutter::EncodableValue>>>
      channels;
  channels.push_back(channel);
}
