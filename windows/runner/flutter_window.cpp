#include "flutter_window.h"
#include <optional>
#include <vector>
#include <string>
#include "flutter/generated_plugin_registrant.h"
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <dwmapi.h>
#include <shellapi.h>

#pragma comment(lib, "dwmapi.lib")
#pragma comment(lib, "shell32.lib")

FlutterWindow::FlutterWindow(const flutter::DartProject &project) : project_(project) {}
FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate()
{
  if (!Win32Window::OnCreate())
    return false;

  HWND hWnd = GetHandle();

  // Windows'un standart başlık çubuğunu kaldır (Frameless)
  LONG_PTR style = GetWindowLongPtr(hWnd, GWL_STYLE);
  style &= ~WS_CAPTION;
  SetWindowLongPtr(hWnd, GWL_STYLE, style);
  SetWindowPos(hWnd, nullptr, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);

  RECT frame = GetClientArea();
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view())
    return false;
  RegisterPlugins(flutter_controller_->engine());

  auto channel = std::make_unique<flutter::MethodChannel<>>(
      flutter_controller_->engine()->messenger(), "winricer/window_manager", &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler([hWnd](const flutter::MethodCall<> &call, std::unique_ptr<flutter::MethodResult<>> result)
                                {
    if (call.method_name() == "closeApp") {
      PostMessage(hWnd, WM_CLOSE, 0, 0);
      result->Success();
      return;
    }
    if (call.method_name() == "minimizeApp") {
      ShowWindow(hWnd, SW_MINIMIZE);
      result->Success();
      return;
    }
    if (call.method_name() == "toggleTaskbar") {
      const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
      bool hide = true;
      if (args) {
        auto it = args->find(flutter::EncodableValue("hide"));
        if (it != args->end() && std::holds_alternative<bool>(it->second)) {
          hide = std::get<bool>(it->second);
        }
      }
      APPBARDATA abd = { sizeof(APPBARDATA), FindWindowW(L"Shell_TrayWnd", nullptr) };
      abd.lParam = hide ? ABS_AUTOHIDE : ABS_ALWAYSONTOP;
      SHAppBarMessage(ABM_SETSTATE, &abd);
      result->Success();
      return;
    }
    result->NotImplemented(); });

  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  flutter_controller_->engine()->SetNextFrameCallback([&]()
                                                      { this->Show(); });
  flutter_controller_->ForceRedraw();
  return true;
}

void FlutterWindow::OnDestroy()
{
  if (flutter_controller_)
    flutter_controller_ = nullptr;
  Win32Window::OnDestroy();
}

LRESULT FlutterWindow::MessageHandler(HWND hwnd, UINT const message, WPARAM const wparam, LPARAM const lparam) noexcept
{
  if (flutter_controller_)
  {
    std::optional<LRESULT> result = flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam, lparam);
    if (result)
      return *result;
  }
  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}