#include "flutter_window.h"

#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cmath>
#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // The window is deliberately NOT shown here (the stock runner shows it after
  // the first frame). The app lives in the tray and decides for itself when
  // and as what its one window appears -- splash, reminder popup, settings --
  // so opening the app must not put a window on screen by itself.

  // Window tweaks window_manager has no (working) API for. `setToolWindow`
  // keeps the window out of the taskbar and Alt+Tab, which the splash and the
  // reminder popup must not appear in. Takes effect the next time the window
  // is shown, so the Dart side calls it while the window is hidden.
  window_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "dhikr_reminder/window",
          &flutter::StandardMethodCodec::GetInstance());
  window_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() == "setToolWindow") {
          const auto* enable = std::get_if<bool>(call.arguments());
          if (enable == nullptr) {
            result->Error("bad-args", "setToolWindow expects a bool");
            return;
          }
          HWND hwnd = GetHandle();
          LONG_PTR style = ::GetWindowLongPtr(hwnd, GWL_EXSTYLE);
          if (*enable) {
            style = (style | WS_EX_TOOLWINDOW) & ~WS_EX_APPWINDOW;
          } else {
            style = (style & ~WS_EX_TOOLWINDOW) | WS_EX_APPWINDOW;
          }
          ::SetWindowLongPtr(hwnd, GWL_EXSTYLE, style);
          result->Success();
        } else if (call.method_name() == "centerOnCursorMonitor") {
          // Centres the window on the monitor the cursor is on -- the true
          // centre of the whole screen, not of the area above the taskbar --
          // working in physical pixels throughout so it holds at any
          // resolution or DPI, including a second monitor with a different
          // scale. The size arrives in logical pixels and is shrunk to fit.
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          auto number = [args](const char* key) -> double {
            if (args == nullptr) return 0;
            auto it = args->find(flutter::EncodableValue(key));
            if (it == args->end()) return 0;
            if (const auto* d = std::get_if<double>(&it->second)) return *d;
            if (const auto* i = std::get_if<int32_t>(&it->second)) return *i;
            return 0;
          };
          const double logical_width = number("width");
          const double logical_height = number("height");
          const double logical_gap = number("gap");
          if (logical_width <= 0 || logical_height <= 0) {
            result->Error("bad-args",
                          "centerOnCursorMonitor expects width and height");
            return;
          }

          HWND hwnd = GetHandle();
          POINT cursor;
          ::GetCursorPos(&cursor);
          HMONITOR monitor =
              ::MonitorFromPoint(cursor, MONITOR_DEFAULTTONEAREST);
          MONITORINFO info = {sizeof(info)};
          ::GetMonitorInfo(monitor, &info);
          const RECT screen = info.rcMonitor;

          // Step onto the monitor first: if its DPI differs, Windows re-scales
          // the window (see WM_DPICHANGED in win32_window.cpp) and the DPI to
          // size the window by is only known after that.
          const UINT dpi_before = ::GetDpiForWindow(hwnd);
          RECT current;
          ::GetWindowRect(hwnd, &current);
          ::SetWindowPos(hwnd, nullptr, screen.left, screen.top,
                         current.right - current.left,
                         current.bottom - current.top,
                         SWP_NOZORDER | SWP_NOACTIVATE);
          const UINT dpi = ::GetDpiForWindow(hwnd);
          const double scale = dpi / 96.0;

          const int width = static_cast<int>(std::lround(std::min(
              logical_width * scale,
              (screen.right - screen.left) - 2 * logical_gap * scale)));
          const int height = static_cast<int>(std::lround(std::min(
              logical_height * scale,
              (screen.bottom - screen.top) - 2 * logical_gap * scale)));
          const int x = screen.left + ((screen.right - screen.left) - width) / 2;
          const int y = screen.top + ((screen.bottom - screen.top) - height) / 2;
          ::SetWindowPos(hwnd, nullptr, x, y, width, height,
                         SWP_NOZORDER | SWP_NOACTIVATE);
          result->Success(flutter::EncodableValue(dpi != dpi_before));
        } else {
          result->NotImplemented();
        }
      });

  // Flutter can complete the first frame before anything asks for one; keep a
  // frame pending so the engine is warm by the time the window is first shown.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
