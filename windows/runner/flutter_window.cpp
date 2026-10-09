#include "flutter_window.h"

#include <flutter/standard_method_codec.h>

#include <shellapi.h>  // SHQueryUserNotificationState
#include <mmsystem.h>  // PlaySound

#pragma comment(lib, "winmm.lib")

#include <algorithm>
#include <cmath>
#include <optional>

#include "flutter/generated_plugin_registrant.h"

namespace {

// The effective DPI of [monitor], from shcore (Windows 8.1+), loaded on demand
// so the runner needs no extra link dependency. Falls back to the system DPI.
UINT DpiForMonitor(HMONITOR monitor) {
  using GetDpiForMonitorFn = HRESULT(WINAPI*)(HMONITOR, int, UINT*, UINT*);
  static const auto get_dpi_for_monitor = [] {
    HMODULE shcore = ::LoadLibraryW(L"Shcore.dll");
    return shcore ? reinterpret_cast<GetDpiForMonitorFn>(
                        ::GetProcAddress(shcore, "GetDpiForMonitor"))
                  : nullptr;
  }();
  UINT dpi_x = 0, dpi_y = 0;
  constexpr int kMdtEffectiveDpi = 0;
  if (get_dpi_for_monitor &&
      SUCCEEDED(get_dpi_for_monitor(monitor, kMdtEffectiveDpi, &dpi_x, &dpi_y)) &&
      dpi_x != 0) {
    return dpi_x;
  }
  return ::GetDpiForSystem();
}

// Moves and sizes [hwnd] to [rect] (physical pixels), twice. Crossing onto a
// monitor with another DPI makes Windows send WM_DPICHANGED, whose handler
// (win32_window.cpp) resizes the window to the rect Windows suggests -- which
// would undo the size just set. The second call, made once the window is
// already on that monitor, is not interrupted and so is the one that sticks.
void PlaceWindow(HWND hwnd, const RECT& rect) {
  for (int i = 0; i < 2; ++i) {
    ::SetWindowPos(hwnd, nullptr, rect.left, rect.top, rect.right - rect.left,
                   rect.bottom - rect.top, SWP_NOZORDER | SWP_NOACTIVATE);
  }
}

}  // namespace

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

          // The scale of the monitor the window is going TO. Asking the window
          // itself right after moving it is wrong: Windows has not switched
          // its DPI yet, so it still answers with the monitor it came from.
          const UINT dpi = DpiForMonitor(monitor);
          const UINT dpi_before = ::GetDpiForWindow(hwnd);
          const double scale = dpi / 96.0;

          const int width = static_cast<int>(std::lround(std::min(
              logical_width * scale,
              (screen.right - screen.left) - 2 * logical_gap * scale)));
          const int height = static_cast<int>(std::lround(std::min(
              logical_height * scale,
              (screen.bottom - screen.top) - 2 * logical_gap * scale)));
          const int x = screen.left + ((screen.right - screen.left) - width) / 2;
          const int y = screen.top + ((screen.bottom - screen.top) - height) / 2;
          PlaceWindow(hwnd, {x, y, x + width, y + height});
          result->Success(flutter::EncodableValue(dpi != dpi_before));
        } else if (call.method_name() == "syncContent") {
          SyncContentSize();
          result->Success();
        } else if (call.method_name() == "restoreWindow") {
          // Leaves maximized state: a window hidden and re-shown while
          // maximized comes back maximized, whatever size it is then given.
          HWND hwnd = GetHandle();
          if (::IsZoomed(hwnd) || ::IsIconic(hwnd)) {
            ::ShowWindow(hwnd, SW_RESTORE);
          }
          result->Success();
        } else if (call.method_name() == "placeNearCursor") {
          // Puts a popup of the given logical size beside the cursor (which is
          // on the tray icon): centred on it horizontally, above it when the
          // icon is in the lower half of the monitor's work area and below it
          // otherwise, always fully inside the work area. Physical pixels
          // throughout, for the same reason as centerOnCursorMonitor.
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
                          "placeNearCursor expects width and height");
            return;
          }

          HWND hwnd = GetHandle();
          POINT cursor;
          ::GetCursorPos(&cursor);
          HMONITOR monitor =
              ::MonitorFromPoint(cursor, MONITOR_DEFAULTTONEAREST);
          MONITORINFO info = {sizeof(info)};
          ::GetMonitorInfo(monitor, &info);
          const RECT work = info.rcWork;

          const UINT dpi = DpiForMonitor(monitor);
          const UINT dpi_before = ::GetDpiForWindow(hwnd);
          const double scale = dpi / 96.0;
          const int gap = static_cast<int>(std::lround(logical_gap * scale));
          const int width = static_cast<int>(std::lround(logical_width * scale));
          const int height =
              static_cast<int>(std::lround(logical_height * scale));

          const bool above = cursor.y > (work.top + work.bottom) / 2;
          auto clamp_into = [](int value, int low, int high) {
            if (high < low) high = low;
            return value < low ? low : (value > high ? high : value);
          };
          const int x = clamp_into(cursor.x - width / 2, work.left + gap,
                                   work.right - width - gap);
          const int y = clamp_into(above ? cursor.y - height - gap
                                         : cursor.y + gap,
                                   work.top + gap, work.bottom - height - gap);
          PlaceWindow(hwnd, {x, y, x + width, y + height});
          result->Success(flutter::EncodableValue(dpi != dpi_before));
        } else if (call.method_name() == "playChime") {
          // The finishing chime: a small WAV the app made, played once from
          // memory without blocking. Windows' own volume and mute apply.
          const auto* bytes = std::get_if<std::vector<uint8_t>>(call.arguments());
          if (bytes == nullptr || bytes->size() < 44) {
            result->Error("bad-args", "playChime expects WAV bytes");
            return;
          }
          chime_ = *bytes;
          ::PlaySoundW(reinterpret_cast<LPCWSTR>(chime_.data()), nullptr,
                       SND_MEMORY | SND_ASYNC | SND_NODEFAULT);
          result->Success();
        } else if (call.method_name() == "userState") {
          // Whether this is a bad moment for a reminder: what Windows says
          // about full-screen apps, presentations and Focus Assist, and how
          // long since the last keyboard or mouse input. Reads two system
          // values and touches nothing, so it is safe to ask every reminder.
          QUERY_USER_NOTIFICATION_STATE state = QUNS_ACCEPTS_NOTIFICATIONS;
          if (FAILED(::SHQueryUserNotificationState(&state))) {
            state = QUNS_ACCEPTS_NOTIFICATIONS;
          }
          int idle_seconds = 0;
          LASTINPUTINFO input = {sizeof(input)};
          if (::GetLastInputInfo(&input)) {
            idle_seconds =
                static_cast<int>((::GetTickCount() - input.dwTime) / 1000);
          }
          flutter::EncodableMap map;
          map[flutter::EncodableValue("notificationState")] =
              flutter::EncodableValue(static_cast<int32_t>(state));
          map[flutter::EncodableValue("idleSeconds")] =
              flutter::EncodableValue(static_cast<int32_t>(idle_seconds));
          result->Success(flutter::EncodableValue(map));
        } else {
          result->NotImplemented();
        }
      });

  // Flutter can complete the first frame before anything asks for one; keep a
  // frame pending so the engine is warm by the time the window is first shown.
  flutter_controller_->ForceRedraw();

  return true;
}

// The Flutter view is a child window that has to be kept the size of the
// window's client area. Normally WM_SIZE does that (win32_window.cpp), but a
// window that is maximized, restored, re-framed (frameless <-> titled) and
// re-sized in quick succession can end up with its view left at an earlier
// size. The surface then renders for the stale size and is cropped or
// stretched by the window -- the card appears several times too big until
// something makes the window resize again.
void FlutterWindow::SyncContentSize() {
  if (!flutter_controller_ || !flutter_controller_->view()) return;
  HWND content = flutter_controller_->view()->GetNativeWindow();
  if (content == nullptr) return;
  const RECT area = GetClientArea();
  RECT current;
  ::GetWindowRect(content, &current);
  if (current.right - current.left == area.right - area.left &&
      current.bottom - current.top == area.bottom - area.top) {
    return;
  }
  ::MoveWindow(content, area.left, area.top, area.right - area.left,
               area.bottom - area.top, TRUE);
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

  // A newer copy of the app has been started and wants this one gone (see
  // `ReplaceRunningInstance` in main.cpp). Dart does the quitting, so the tray
  // icon is removed properly instead of lingering after the process is gone.
  static const UINT kQuitMessage = ::RegisterWindowMessageW(L"DhikrReminder.Quit");
  if (message == kQuitMessage) {
    if (window_channel_) {
      window_channel_->InvokeMethod("quit", nullptr);
    } else {
      ::ExitProcess(0);
    }
    return 0;
  }

  if (message == WM_WINDOWPOSCHANGED || message == WM_DPICHANGED ||
      message == WM_SIZE) {
    // After the base class has done its own sizing.
    const LRESULT handled =
        Win32Window::MessageHandler(hwnd, message, wparam, lparam);
    SyncContentSize();
    return handled;
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
