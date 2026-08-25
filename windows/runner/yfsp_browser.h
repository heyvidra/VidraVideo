#ifndef RUNNER_YFSP_BROWSER_H_
#define RUNNER_YFSP_BROWSER_H_

#include <flutter/flutter_engine.h>

// Registers the `vidra/yfsp_browser` method channel on |engine|.
//
// The Windows counterpart of macOS's YfspBrowser (see
// macos/Runner/MainFlutterWindow.swift): one WebView2, hidden while it carries
// yfsp's requests and shown as a window while the user passes the Cloudflare
// challenge. Same channel name and the same `solve` / `keys` / `fetch` methods,
// so the Dart side (lib/.../yfsp/yfsp_challenge.dart) needs no per-platform code.
//
// Called from FlutterWindow::OnCreate for every window — including the player
// window bitsdojo builds from the same class — so the process-wide WebView2 and
// its session are shared, exactly as on macOS.
void RegisterYfspBrowser(flutter::FlutterEngine* engine);

#endif  // RUNNER_YFSP_BROWSER_H_
