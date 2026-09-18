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
#pragma comment(lib, "advapi32.lib")

// Arama Çubuğunu Butona Çevirme Fonksiyonu
void SetSearchMode(bool iconOnly) {
  HKEY hKey;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, L"Software\\Microsoft\\Windows\\CurrentVersion\\Search", 0, nullptr, 0, KEY_SET_VALUE, nullptr, &hKey, nullptr) == ERROR_SUCCESS) {
    DWORD mode = iconOnly ? 1 : 2; // 1: Yalnızca Arama Butonu, 2: Uzun Arama Çubuğu
    RegSetValueExW(hKey, L"SearchboxTaskbarMode", 0, REG_DWORD, (const BYTE*)&mode, sizeof(mode));
    RegCloseKey(hKey);
  }
  // Explorer'a anında değişikliği bildir
  SendMessageTimeoutW(HWND_BROADCAST, WM_SETTINGCHANGE, 0, (LPARAM)L"TraySettings", SMTO_ABORTIFHUNG, 200, nullptr);
}

// Görev Çubuğunu Kavisli Adaya Çevirme Fonksiyonu (RoundedTB Mantığı)
void ApplyTaskbarGeometry(bool isActive, int radius, int marginX, int bottomMargin) {
  HWND hTaskbar = FindWindowW(L"Shell_TrayWnd", nullptr);
  if (!hTaskbar) return;

  // Çubuğun görünür olduğundan emin ol
  APPBARDATA abd = { sizeof(APPBARDATA), hTaskbar };
  abd.lParam = ABS_ALWAYSONTOP;
  SHAppBarMessage(ABM_SETSTATE, &abd);
  ShowWindow(hTaskbar, SW_SHOW);

  if (isActive) {
    RECT rc;
    GetWindowRect(hTaskbar, &rc);
    int totalWidth = rc.right - rc.left;
    int totalHeight = rc.bottom - rc.top;

    int top = 0; // İkonlar sıkışmasın diye üstten pay sıfır
    int bottom = totalHeight - bottomMargin;
    int r = radius * 2;

    int left = marginX;
    int right = totalWidth - marginX;

    if (right > left && bottom > top) {
      HRGN rgn = CreateRoundRectRgn(left, top, right, bottom, r, r);
      SetWindowRgn(hTaskbar, rgn, TRUE);
    }
  } else {
    // Kapatıldığında orijinal haline döndür
    SetWindowRgn(hTaskbar, NULL, TRUE);
  }

  SetWindowPos(hTaskbar, nullptr, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
  RedrawWindow(hTaskbar, NULL, NULL, RDW_INVALIDATE | RDW_UPDATENOW | RDW_ALLCHILDREN | RDW_FRAME);
}

FlutterWindow::FlutterWindow(const flutter::DartProject &project) : project_(project) {}
FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) return false;

  HWND hWnd = GetHandle();

  LONG_PTR style = GetWindowLongPtr(hWnd, GWL_STYLE);
  style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
  style |= WS_POPUP;
  SetWindowLongPtr(hWnd, GWL_STYLE, style);

  int sW = GetSystemMetrics(SM_CXSCREEN);
  int sH = GetSystemMetrics(SM_CYSCREEN);
  int winW = 940;
  int winH = 620;
  SetWindowPos(hWnd, nullptr, (sW - winW) / 2, (sH - winH) / 2, winW, winH, SWP_FRAMECHANGED | SWP_SHOWWINDOW);

  DWM_WINDOW_CORNER_PREFERENCE pref = DWMWCP_ROUND;
  DwmSetWindowAttribute(hWnd, DWMWA_WINDOW_CORNER_PREFERENCE, &pref, sizeof(pref));

  RECT frame = GetClientArea();
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) return false;
  RegisterPlugins(flutter_controller_->engine());

  auto channel = std::make_unique<flutter::MethodChannel<>>(
      flutter_controller_->engine()->messenger(), "winricer/window_manager", &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler([](const flutter::MethodCall<> &call, std::unique_ptr<flutter::MethodResult<>> result) {
    if (call.method_name() == "closeApp") {
      ApplyTaskbarGeometry(false, 0, 0, 0);
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
    if (call.method_name() == "setSearchButton") {
      const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
      if (args) {
        auto it = args->find(flutter::EncodableValue("iconOnly"));
        if (it != args->end() && std::holds_alternative<bool>(it->second)) {
          SetSearchMode(std::get<bool>(it->second));
        }
      }
      result->Success(flutter::EncodableValue(true));
      return;
    }
    if (call.method_name() == "restartExplorer") {
      system("taskkill /f /im explorer.exe & start explorer.exe");
      result->Success(flutter::EncodableValue(true));
      return;
    }
    if (call.method_name() == "updateTaskbarGeometry") {
      const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
      if (args) {
        bool isActive = false;
        int radius = 18;
        int marginX = 60;
        int bottomMargin = 4;

        auto active_it = args->find(flutter::EncodableValue("isActive"));
        if (active_it != args->end() && std::holds_alternative<bool>(active_it->second)) isActive = std::get<bool>(active_it->second);
        auto r_it = args->find(flutter::EncodableValue("radius"));
        if (r_it != args->end() && std::holds_alternative<double>(r_it->second)) radius = (int)std::get<double>(r_it->second);
        auto m_it = args->find(flutter::EncodableValue("margin"));
        if (m_it != args->end() && std::holds_alternative<double>(m_it->second)) marginX = (int)std::get<double>(m_it->second);
        auto b_it = args->find(flutter::EncodableValue("bottomMargin"));
        if (b_it != args->end() && std::holds_alternative<double>(b_it->second)) bottomMargin = (int)std::get<double>(b_it->second);

        ApplyTaskbarGeometry(isActive, radius, marginX, bottomMargin);
      }
      result->Success(flutter::EncodableValue(true));
      return;
    }
    result->NotImplemented();
  });

  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  flutter_controller_->engine()->SetNextFrameCallback([&]() { this->Show(); });
  flutter_controller_->ForceRedraw();
  return true;
}

void FlutterWindow::OnDestroy() {
  ApplyTaskbarGeometry(false, 0, 0, 0);
  if (flutter_controller_) flutter_controller_ = nullptr;
  Win32Window::OnDestroy();
}

LRESULT FlutterWindow::MessageHandler(HWND hwnd, UINT const message, WPARAM const wparam, LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result = flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam, lparam);
    if (result) return *result;
  }
  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}