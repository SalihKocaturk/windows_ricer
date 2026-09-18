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
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "shell32.lib")

// RoundedTB Motoru: Windows Görev Çubuğunu Canlı Olarak Kavisli Adaya Çevir
void ApplyRoundedTaskbar(bool isActive, int radius, int marginX, int marginY)
{
  HWND hTaskbar = FindWindowW(L"Shell_TrayWnd", nullptr);
  if (!hTaskbar)
    return;

  // 1. Önceki gizlemeleri iptal et, çubuğu kesinlikle ekranda görünür yap
  APPBARDATA abd = {sizeof(APPBARDATA), hTaskbar};
  abd.lParam = ABS_ALWAYSONTOP;
  SHAppBarMessage(ABM_SETSTATE, &abd);
  ShowWindow(hTaskbar, SW_SHOW);

  if (isActive)
  {
    RECT rc;
    GetWindowRect(hTaskbar, &rc);
    int totalWidth = rc.right - rc.left;
    int totalHeight = rc.bottom - rc.top;

    int left = marginX;
    int top = marginY;
    int right = totalWidth - marginX;
    int bottom = totalHeight - marginY;

    if (right > left && bottom > top)
    {
      HRGN rgn = CreateRoundRectRgn(left, top, right, bottom, radius * 2, radius * 2);
      SetWindowRgn(hTaskbar, rgn, TRUE);
    }
  }
  else
  {
    // Kapatıldığında orijinal dikdörtgen haline geri döndür
    SetWindowRgn(hTaskbar, NULL, TRUE);
  }

  // 2. Windows DWM motoruna çerçevenin değiştiğini bildir ve anında yeniden çizdir
  SetWindowPos(hTaskbar, nullptr, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
  RedrawWindow(hTaskbar, NULL, NULL, RDW_INVALIDATE | RDW_UPDATENOW | RDW_ALLCHILDREN | RDW_FRAME);
}

FlutterWindow::FlutterWindow(const flutter::DartProject &project) : project_(project) {}
FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate()
{
  if (!Win32Window::OnCreate())
    return false;

  HWND hWnd = GetHandle();

  // WinRicer'ın kendi penceresini frameless yap
  LONG_PTR style = GetWindowLongPtr(hWnd, GWL_STYLE);
  style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
  style |= WS_POPUP;
  SetWindowLongPtr(hWnd, GWL_STYLE, style);

  // Pencereyi ekranın ortasında normal 940x620 Dashboard olarak aç
  int screenWidth = GetSystemMetrics(SM_CXSCREEN);
  int screenHeight = GetSystemMetrics(SM_CYSCREEN);
  int winWidth = 940;
  int winHeight = 620;
  int posX = (screenWidth - winWidth) / 2;
  int posY = (screenHeight - winHeight) / 2;

  SetWindowPos(hWnd, nullptr, posX, posY, winWidth, winHeight, SWP_FRAMECHANGED | SWP_SHOWWINDOW);

  DWM_WINDOW_CORNER_PREFERENCE pref = DWMWCP_ROUND;
  DwmSetWindowAttribute(hWnd, DWMWA_WINDOW_CORNER_PREFERENCE, &pref, sizeof(pref));

  RECT frame = GetClientArea();
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view())
    return false;
  RegisterPlugins(flutter_controller_->engine());

  auto channel = std::make_unique<flutter::MethodChannel<>>(
      flutter_controller_->engine()->messenger(), "winricer/window_manager", &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler([](const flutter::MethodCall<> &call, std::unique_ptr<flutter::MethodResult<>> result)
                                {
    if (call.method_name() == "closeApp") {
      ApplyRoundedTaskbar(false, 0, 0, 0); // Kapanırken görev çubuğunu orijinale döndür
      PostMessage(FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", nullptr), WM_CLOSE, 0, 0);
      result->Success();
      return;
    }
    if (call.method_name() == "minimizeApp") {
      HWND hApp = FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", nullptr);
      if (hApp) ShowWindow(hApp, SW_MINIMIZE);
      result->Success();
      return;
    }
    if (call.method_name() == "updateRoundedTaskbar") {
      const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
      if (args) {
        bool isActive = false;
        int radius = 18;
        int marginX = 90;
        int marginY = 6;

        auto active_it = args->find(flutter::EncodableValue("isActive"));
        if (active_it != args->end() && std::holds_alternative<bool>(active_it->second)) {
          isActive = std::get<bool>(active_it->second);
        }

        auto radius_it = args->find(flutter::EncodableValue("radius"));
        if (radius_it != args->end() && std::holds_alternative<double>(radius_it->second)) {
          radius = (int)std::get<double>(radius_it->second);
        }

        auto margin_it = args->find(flutter::EncodableValue("margin"));
        if (margin_it != args->end() && std::holds_alternative<double>(margin_it->second)) {
          marginX = (int)std::get<double>(margin_it->second);
        }

        ApplyRoundedTaskbar(isActive, radius, marginX, marginY);
      }
      result->Success(flutter::EncodableValue(true));
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
  ApplyRoundedTaskbar(false, 0, 0, 0); // Uygulama kapanırsa görev çubuğunu normale döndür
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