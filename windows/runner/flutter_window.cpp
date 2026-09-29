#include "flutter_window.h"

#include <flutter/standard_method_codec.h>

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
