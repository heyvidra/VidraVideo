import Cocoa
import FlutterMacOS
import IOKit.pwr_mgt
import WebKit

import bitsdojo_window_macos

class MainFlutterWindow: BitsdojoWindow {
  override func bitsdojo_window_configure() -> UInt {
    return BDW_CUSTOM_FRAME | BDW_HIDE_ON_STARTUP
  }

  /// Where macOS centres the traffic lights vertically.
  ///
  /// The toolbar pill is the top row now and the lights sit ON it, so this has
  /// to agree with where that pill's centre lands: 6pt of top margin plus a
  /// 44pt pill centres at 28, and the system centres the buttons at half this
  /// number. Move the pill's geometry and this moves with it.
  override func bitsdojo_window_title_bar_height() -> Double {
    return 56.0
  }

  override func setupFlutter() {
    super.setupFlutter()

    // Register plugins for this window's Flutter engine
    if let flutterViewController = self.contentViewController as? FlutterViewController {
      RegisterGeneratedPlugins(registry: flutterViewController)
      // ...which just pointed the notification centre at a per-engine object.
      // Take it back before that object can outlive its window.
      NotificationCenterDelegate.takeOver()
      // The cast lives in the main engine, and the power assertion is
      // process-wide, so this channel belongs on this engine alone.
      SleepBlocker.register(with: flutterViewController.engine.binaryMessenger)
      // The catalog — where a Cloudflare wall is first met — lives in the
      // main engine, and so does the WebView that carries yfsp's requests
      // past that wall.
      YfspBrowser.register(with: flutterViewController.engine.binaryMessenger)
    }
  }
}

/// A real browser engine that carries yfsp's requests, because a stolen
/// cookie will not.
///
/// yfsp sits behind Cloudflare's interactive challenge. A human can pass it —
/// that is what [solve] is for — but the clearance Cloudflare mints is bound
/// to the *browser's* TLS fingerprint, not just its cookie: replaying the
/// cookie from Dart's HTTP client is refused all the same (measured). So the
/// requests themselves are made from inside this WKWebView, whose fingerprint
/// and cookie jar are the ones the challenge cleared.
///
/// One offscreen webview, parked on the site's own origin, serves every call:
/// [fetch] runs an in-page `fetch()` from that origin (same-origin for the key
/// page, same-site for the API — which the site's own SPA relies on being
/// allowed), and returns the raw response text. If a cross-origin call is
/// refused by CORS after all, it falls back to a top-level navigation and
/// reads the body back. Requests are serialised: one navigation slot exists,
/// the rate limiter wants the restraint anyway.
///
/// The default (persistent) data store is deliberate: a challenge passed once
/// stays passed across a restart, and across the app's other engines, which
/// share this same store.
final class YfspBrowser: NSObject, WKNavigationDelegate, NSWindowDelegate {
  static let shared = YfspBrowser()

  /// The page the webview parks on. It carries the signing keys in its inline
  /// `pConfig`, and it is on www.yfsp.tv, so the in-page fetches it hosts reach
  /// the m10 API cross-origin (the shape that answers with JSON).
  private let home = URL(string: "https://www.yfsp.tv/list/drama")!

  private var webView: WKWebView?
  private var userAgent =
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
    + "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

  // One navigation at a time. `nav` is the single continuation slot the
  // delegate fulfils; `queue`/`busy` serialise whole operations around it.
  private var nav: ((Error?) -> Void)?
  private var queue: [() -> Void] = []
  private var busy = false

  // solve()
  private var solveWindow: NSWindow?
  private var solveTimer: Timer?
  private var solvePending: ((Bool) -> Void)?

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "vidra/yfsp_browser",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any]
      if let ua = args?["userAgent"] as? String { shared.userAgent = ua }
      switch call.method {
      case "solve":
        shared.enqueue { done in shared.solve { ok in result(ok); done() } }
      case "fetch":
        guard let u = args?["url"] as? String, let url = URL(string: u) else {
          result(FlutterError(code: "bad_args", message: "url missing", details: nil))
          return
        }
        shared.enqueue { done in
          shared.fetch(url) { env in result(env); done() }
        }
      case "keys":
        shared.enqueue { done in
          shared.readKeys { env in result(env); done() }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Serial queue

  private func enqueue(_ op: @escaping (_ done: @escaping () -> Void) -> Void) {
    DispatchQueue.main.async {
      self.queue.append { op { self.next() } }
      self.pump()
    }
  }

  private func pump() {
    guard !busy, !queue.isEmpty else { return }
    busy = true
    queue.removeFirst()()
  }

  private func next() {
    busy = false
    pump()
  }

  // MARK: - WebView plumbing

  private func ensureWebView() -> WKWebView {
    if let w = webView { return w }
    let cfg = WKWebViewConfiguration()
    cfg.websiteDataStore = .default()
    let w = WKWebView(
      frame: NSRect(x: 0, y: 0, width: 480, height: 640),
      configuration: cfg
    )
    // Deliberately NOT setting a custom User-Agent. Forcing a Chrome UA onto
    // WebKit hands Cloudflare a contradiction — a Chrome claim on a Safari
    // TLS/JS fingerprint — which reads as automation and leaves the Turnstile
    // spinning forever. The native Safari UA matches the engine underneath,
    // which is the whole point of solving in a real browser.
    w.navigationDelegate = self
    webView = w
    return w
  }

  private func navigate(_ w: WKWebView, to url: URL, _ done: @escaping (Error?) -> Void) {
    nav = done
    w.load(URLRequest(url: url))
  }

  func webView(_ w: WKWebView, didFinish _: WKNavigation!) {
    let c = nav; nav = nil; c?(nil)
  }
  func webView(_ w: WKWebView, didFail _: WKNavigation!, withError e: Error) {
    let c = nav; nav = nil; c?(e)
  }
  func webView(_ w: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError e: Error) {
    let c = nav; nav = nil; c?(e)
  }

  /// Parks the webview on the SITE's own origin (www.yfsp.tv) before an in-page
  /// fetch. The API lives on m10.yfsp.tv, so the fetch is deliberately
  /// CROSS-origin: measured against the live site, m10 answers a cross-origin
  /// XHR from www with JSON (and the CORS headers to read it), while a
  /// same-origin request straight at m10 hits a bare IIS that 404s. This is
  /// also the origin whose Cloudflare clearance the solve minted, and whose
  /// page carries the signing keys.
  private func park(_ w: WKWebView, for url: URL, _ done: @escaping (Error?) -> Void) {
    if w.url?.host == home.host {
      done(nil)
    } else {
      navigate(w, to: home, done)
    }
  }

  // MARK: - fetch

  /// Runs one request by NAVIGATING the browser to the (signed) URL and reading
  /// the response document back — the shape a human gets typing the URL in, and
  /// the one that returns the API's JSON. A cross-origin in-page XHR to the same
  /// URL comes back, in this WKWebView, as the site's HTML shell instead; a
  /// top-level navigation does not. Answers Dart `{status, body}`; a transport
  /// failure comes back as `{status: -1, error: ...}`.
  private func fetch(_ url: URL, _ completion: @escaping ([String: Any]) -> Void) {
    let w = ensureWebView()
    fetchByNavigation(w, url, completion)
  }

  /// Reads the signing key pair out of the key page's inline `pConfig`.
  ///
  /// It NAVIGATES to the page and reads the DOM rather than XHR-fetching it:
  /// measured against the live site, an XHR of the same URL comes back with no
  /// `pConfig` at all (the keys are embedded only for a top-level navigation),
  /// so a scraped-over-fetch key is stale/absent and every signed call it makes
  /// is refused. A navigation load carries the real, current pair.
  private func readKeys(_ completion: @escaping ([String: Any]) -> Void) {
    let w = ensureWebView()
    navigate(w, to: home) { err in
      if let err = err {
        completion(["error": "nav: \(err.localizedDescription)"])
        return
      }
      let js = """
        (function(){
          var h = document.documentElement.outerHTML;
          var m = h.match(/"pConfig"\\s*:\\s*\\{([^{}]*)\\}/);
          if(!m) return JSON.stringify({});
          var pub = (m[1].match(/"publicKey"\\s*:\\s*"([^"]+)"/)||[])[1] || "";
          var priv = (m[1].match(/"privateKey"\\s*:\\s*\\[\\s*"([^"]+)"/)||[])[1] || "";
          return JSON.stringify({pub:pub, priv:priv});
        })()
        """
      w.evaluateJavaScript(js) { v, _ in
        if let s = v as? String, let d = s.data(using: .utf8),
           let o = try? JSONSerialization.jsonObject(with: d) as? [String: Any] {
          completion(o)
        } else {
          completion([:])
        }
      }
    }
  }

  private func fetchByNavigation(
    _ w: WKWebView, _ url: URL, _ completion: @escaping ([String: Any]) -> Void
  ) {
    navigate(w, to: url) { err in
      if let err = err {
        completion(["status": -1, "error": "nav: \(err.localizedDescription)"])
        return
      }
      w.evaluateJavaScript(
        "document.body ? document.body.innerText : document.documentElement.innerText"
      ) { value, _ in
        let body = value as? String ?? ""
        // Status is unavailable from a navigation; Dart infers challenge vs
        // payload from the body. The webview is now parked on the target's
        // own origin, which is where the next same-origin fetch wants it.
        completion(["status": 0, "body": body])
      }
    }
  }

  // MARK: - solve

  private func solve(_ completion: @escaping (Bool) -> Void) {
    let w = ensureWebView()
    solvePending = completion

    // Clear the challenge cookies FIRST. A stale cf_clearance from a past
    // session is still in the jar, and polling would spot it the instant the
    // window opens — slamming it shut before the user can act, and handing
    // back a "pass" that the stale cookie cannot actually honour. Cleared,
    // a reappearing cf_clearance can only mean *this* solve minted it.
    let store = w.configuration.websiteDataStore.httpCookieStore
    store.getAllCookies { cookies in
      let group = DispatchGroup()
      for c in cookies where c.domain.hasSuffix("yfsp.tv") && c.name.hasPrefix("cf_") {
        group.enter()
        store.delete(c) { group.leave() }
      }
      group.notify(queue: .main) { self.showSolveWindow(w) }
    }
  }

  private func showSolveWindow(_ w: WKWebView) {
    let win = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 480, height: 640),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    win.title = NSLocalizedString("人机验证", comment: "")
    win.contentView = w
    win.isReleasedWhenClosed = false
    win.delegate = self
    win.center()
    win.makeKeyAndOrderFront(nil)
    // NOT NSApp.activate(ignoringOtherApps:) — forcing app activation kicks the
    // Flutter main window into a re-render mid-open, which trips the engine's
    // Impeller texture crash (flutter#185394). Ordering the window front is
    // enough for the user to reach it.
    solveWindow = win

    navigate(w, to: URL(string: "https://www.yfsp.tv/list/drama")!) { _ in }

    // Turnstile mints the cookie and reloads on its own schedule; one look a
    // second is nothing.
    solveTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      self?.pollClearance()
    }
  }

  private func pollClearance() {
    guard let w = webView, solvePending != nil else { return }
    // Genuine pass is read off the PAGE, not the cookie: Cloudflare sets
    // cf_clearance partway through the flow, so a cookie check alone reports
    // success while the Turnstile is still spinning — and the clearance it
    // hands back is not yet honoured. The challenge page is gone only when its
    // markers are gone.
    w.evaluateJavaScript(
      "document.title + '§' + (document.body ? document.body.innerText.slice(0,60) : '')"
    ) { [weak self] value, _ in
      guard let self = self, self.solvePending != nil else { return }
      let page = (value as? String) ?? ""
      let challenging =
        page.isEmpty
        || page.contains("Just a moment")
        || page.contains("正在进行安全验证")
        || page.contains("请稍候")
        || page.contains("Verifying")
        || page.contains("Checking")
        || page.lowercased().contains("challenge")
      guard !challenging else { return }
      // Passed — the page is the real site now. finishSolve stops the timer;
      // the guard makes sure only the first detection fires it.
      guard self.solveTimer != nil else { return }
      self.finishSolve(true)
    }
  }

  /// Answers the solve waiter once and detaches the webview from the window
  /// (it lives on offscreen as the transport). It is NOT re-navigated: passing
  /// the challenge already left it on the real list/drama page — a same-origin
  /// parking spot — and a re-navigation here only races the fetch that the
  /// waiter is about to trigger, cancelling one or the other (NSURLError -999).
  private func finishSolve(_ ok: Bool) {
    solveTimer?.invalidate()
    solveTimer = nil
    let pending = solvePending
    solvePending = nil
    if let win = solveWindow {
      win.delegate = nil
      win.contentView = nil // keep the webview alive, off the window
      win.close()
      solveWindow = nil
    }
    pending?(ok)
  }

  /// The user closed the window without passing — a "no", not a hang.
  func windowWillClose(_ notification: Notification) {
    guard solvePending != nil else { return }
    finishSolve(false)
  }
}

/// Keeps the Mac awake while it is serving a cast — the Mac, not its screen.
///
/// Casting makes this machine the media server: the television pulls every
/// segment from a local HTTP server here, so a system sleep freezes the
/// process and the picture stops. The obvious fix is the wrong one —
/// `wakelock_plus` asserts `NoDisplaySleep`, which leaves the display lit all
/// evening for a video playing in another room.
///
/// `NoIdleSleep` is the assertion that matches what casting needs: the
/// display sleeps on its usual schedule, the system stays up, the stream
/// keeps flowing. Closing the lid still sleeps the machine and still drops
/// the cast; no assertion overrides a sleep the user asked for.
///
/// Lives in this file rather than its own because a new file under
/// `macos/Runner/` is not in the Xcode target until `project.pbxproj` says
/// so, and hand-editing that to add sixty lines is a worse trade than
/// keeping process-wide helpers together — which is already the pattern
/// below.
final class SleepBlocker {
  static let shared = SleepBlocker()

  private var assertionID: IOPMAssertionID = 0
  private var held = false

  /// Idempotent: a second cast starting before the first is torn down must
  /// not leak an assertion that nothing will ever release.
  func hold(reason: String) -> Bool {
    if held { return true }
    var id: IOPMAssertionID = 0
    let result = IOPMAssertionCreateWithName(
      kIOPMAssertionTypeNoIdleSleep as CFString,
      IOPMAssertionLevel(kIOPMAssertionLevelOn),
      reason as CFString,
      &id
    )
    guard result == kIOReturnSuccess else { return false }
    assertionID = id
    held = true
    return true
  }

  func release() {
    guard held else { return }
    IOPMAssertionRelease(assertionID)
    assertionID = 0
    held = false
  }

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "vidra/sleep_blocker",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "hold":
        let reason = (call.arguments as? [String: Any])?["reason"] as? String
        result(shared.hold(reason: reason ?? "Vidra is casting"))
      case "release":
        shared.release()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

/// Owns `NSUserNotificationCenter`'s delegate for the life of the process.
///
/// local_notifier's plugin makes itself the delegate in `init`, and that
/// property is `assign` — unowned and unchecked. Every player window builds its
/// own engine, so closing one frees the plugin the notification centre is still
/// pointing at, and the next delivered notification messages freed memory
/// (crash: objc_opt_respondsToSelector, SIGTRAP — hours after the window
/// closed, when a subscription update fires).
///
/// ponytail: only `shouldPresent` is reimplemented, so banners still show while
/// Vidra is frontmost. The plugin's show/click/close callbacks stop reaching
/// Dart — nothing here listens to them. Wire them back through this object if
/// something ever does.
@available(macOS, deprecated: 11.0, message: "Mirrors local_notifier's NSUserNotification use.")
final class NotificationCenterDelegate: NSObject, NSUserNotificationCenterDelegate {
  static let shared = NotificationCenterDelegate()

  static func takeOver() {
    NSUserNotificationCenter.default.delegate = shared
  }

  func userNotificationCenter(
    _ center: NSUserNotificationCenter,
    shouldPresent notification: NSUserNotification
  ) -> Bool {
    return true
  }
}
