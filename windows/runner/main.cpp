#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

constexpr wchar_t kWindowTitle[] = L"Dhikr Reminder";
constexpr wchar_t kSingleInstanceMutex[] = L"Local\\DhikrReminder.SingleInstance";
constexpr wchar_t kRunnerWindowClass[] = L"FLUTTER_RUNNER_WIN32_WINDOW";

// Asks the instance that is already running to quit, and waits for it to be
// gone, so the one being started takes its place. The old instance is asked
// politely first (it removes its tray icon on the way out; see
// `RequestQuitMessage` in flutter_window.cpp) and ended outright if it has not
// exited after a few seconds.
void ReplaceRunningInstance() {
  const UINT quit_message = ::RegisterWindowMessageW(L"DhikrReminder.Quit");
  HWND old_window = ::FindWindowW(kRunnerWindowClass, kWindowTitle);
  if (old_window == nullptr) return;

  DWORD pid = 0;
  ::GetWindowThreadProcessId(old_window, &pid);
  if (pid == 0 || pid == ::GetCurrentProcessId()) return;

  HANDLE process = ::OpenProcess(SYNCHRONIZE | PROCESS_TERMINATE, FALSE, pid);
  if (process == nullptr) return;

  ::PostMessageW(old_window, quit_message, 0, 0);
  if (::WaitForSingleObject(process, 4000) != WAIT_OBJECT_0) {
    ::TerminateProcess(process, 0);
    ::WaitForSingleObject(process, 2000);
  }
  ::CloseHandle(process);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Only one copy of the app may run: starting another one replaces the old.
  // The handle is deliberately kept open until the process ends.
  ::CreateMutexW(nullptr, FALSE, kSingleInstanceMutex);
  if (::GetLastError() == ERROR_ALREADY_EXISTS) {
    ReplaceRunningInstance();
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(kWindowTitle, origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
