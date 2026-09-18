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

// Windows DWM Composition Struct (TranslucentTB Motoru)
struct ACCENT_POLICY
{
  int AccentState;
  int AccentFlags;
  DWORD GradientColor;
  int AnimationId;
};

struct WINDOWCOMPOSITIONATTRIBDATA
{
  int Attrib;
  void *pvData;
  int cbData;
};

typedef BOOL(WINAPI *pfnSetWindowCompositionAttribute)(HWND, WINDOWCOMPOSITIONATTRIBDATA *);
static pfnSetWindowCompositionAttribute SetWindowCompositionAttribute = nullptr;

void InitCompositionApi()
{
  HMODULE hUser = GetModuleHandleW(L"user32.dll");
  if (hUser)
  {
    SetWindowCompositionAttribute = (pfnSetWindowCompositionAttribute)GetProcAddress(hUser, "SetWindowCompositionAttribute");
  }
}

// Cam Efekti + Kavisli Ada Fonksiyonu
void ApplyTaskbarStyling(bool isActive, int glassType, double opacity, bool isIsland, int radius, int marginX, int bottomMargin)
{
  HWND hTaskbar = FindWindowW(L"Shell_TrayWnd", nullptr);
  if (!hTaskbar)
    return;

  if (!SetWindowCompositionAttribute)
  {
    InitCompositionApi();
  }

  // Görev çubuğunu görünür yap
  APPBARDATA abd = {sizeof(APPBARDATA), hTaskbar};
  abd.lParam = ABS_ALWAYSONTOP;
  SHAppBarMessage(ABM_SETSTATE, &abd);
  ShowWindow(hTaskbar, SW_SHOW);

  if (isActive)
  {
    // 1. CAM EFEKTİ (DWM)
    if (SetWindowCompositionAttribute)
    {
      ACCENT_POLICY policy = {0, 0, 0, 0};
      DWORD alpha = (DWORD)(opacity * 255.0);
      DWORD tintColor = (alpha << 24) | 0x00181A16; // Koyu zümrüt cam

      if (glassType == 0)
      {
        // Kristal Şeffaf (Clear)
        policy.AccentState = 2; // ACCENT_ENABLE_TRANSPARENTGRADIENT
        policy.AccentFlags = 2;
        policy.GradientColor = (alpha << 24);
      }
      else if (glassType == 1)
      {
        // Buzlu Cam (Acrylic)
        policy.AccentState = 4; // ACCENT_ENABLE_ACRYLICBLURBEHIND
        policy.AccentFlags = 2;
        policy.GradientColor = tintColor;
      }
      else if (glassType == 2)
      {
        // Bulanık Cam (Blur)
        policy.AccentState = 3; // ACCENT_ENABLE_BLURBEHIND
        policy.AccentFlags = 2;
        policy.GradientColor = tintColor;
      }

      WINDOWCOMPOSITIONATTRIBDATA data = {19, &policy, sizeof(policy)};
      SetWindowCompositionAttribute(hTaskbar, &data);

      HWND hSec = FindWindowW(L"Shell_SecondaryTrayWnd", nullptr);
      if (hSec)
        SetWindowCompositionAttribute(hSec, &data);
    }

    // 2. KAVİSLİ ADA ŞEKLİ
    if (isIsland)
    {
      RECT rc;
      GetWindowRect(hTaskbar, &rc);
      int totalWidth = rc.right - rc.left;
      int totalHeight = rc.bottom - rc.top;

      int top = 2;
      int bottom = totalHeight - bottomMargin;
      int r = radius * 2;
      int left = marginX;
      int right = totalWidth - marginX;

      if (right > left && bottom > top)
      {
        HRGN rgn = CreateRoundRectRgn(left, top, right, bottom, r, r);
        SetWindowRgn(hTaskbar, rgn, TRUE);
      }
    }
    else
    {
      SetWindowRgn(hTaskbar, NULL, TRUE); // Tam ekran cam
    }
  }
  else
  {
    if (SetWindowCompositionAttribute)
    {
      ACCENT_POLICY policy = {0, 0, 0, 0};
      WINDOWCOMPOSITIONATTRIBDATA data = {19, &policy, sizeof(policy)};
      SetWindowCompositionAttribute(hTaskbar, &data);
    }
    SetWindowRgn(hTaskbar, NULL, TRUE);
  }

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

  LONG_PTR style = GetWindowLongPtr(hWnd, GWL_STYLE);
  style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
  style |= WS_POPUP;
  SetWindowLongPtr(hWnd, GWL_STYLE, style);

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
      ApplyTaskbarStyling(false, 0, 0.0, false, 0, 0, 0);
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
    if (call.method_name() == "updateTaskbarStyle") {
      const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
      if (args) {
        bool isActive = false;
        int glassType = 1;
        double opacity = 0.35;
        bool isIsland = true;
        int radius = 16;
        int marginX = 40;
        int bottomMargin = 4;

        auto active_it = args->find(flutter::EncodableValue("isActive"));
        if (active_it != args->end() && std::holds_alternative<bool>(active_it->second)) {
          isActive = std::get<bool>(active_it->second);
        }
        auto glass_it = args->find(flutter::EncodableValue("glassType"));
        if (glass_it != args->end() && std::holds_alternative<int>(glass_it->second)) {
          glassType = std::get<int>(glass_it->second);
        }
        auto opacity_it = args->find(flutter::EncodableValue("opacity"));
        if (opacity_it != args->end() && std::holds_alternative<double>(opacity_it->second)) {
          opacity = std::get<double>(opacity_it->second);
        }
        auto island_it = args->find(flutter::EncodableValue("isIsland"));
        if (island_it != args->end() && std::holds_alternative<bool>(island_it->second)) {
          isIsland = std::get<bool>(island_it->second);
        }
        auto radius_it = args->find(flutter::EncodableValue("radius"));
        if (radius_it != args->end() && std::holds_alternative<double>(radius_it->second)) {
          radius = (int)std::get<double>(radius_it->second);
        }
        auto margin_it = args->find(flutter::EncodableValue("margin"));
        if (margin_it != args->end() && std::holds_alternative<double>(margin_it->second)) {
          marginX = (int)std::get<double>(margin_it->second);
        }
        auto bottom_it = args->find(flutter::EncodableValue("bottomMargin"));
        if (bottom_it != args->end() && std::holds_alternative<double>(bottom_it->second)) {
          bottomMargin = (int)std::get<double>(bottom_it->second);
        }

        ApplyTaskbarStyling(isActive, glassType, opacity, isIsland, radius, marginX, bottomMargin);
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
  ApplyTaskbarStyling(false, 0, 0.0, false, 0, 0, 0);
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