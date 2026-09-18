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

// DLL Fonksiyon Göstericileri
typedef bool (*pfnInstallHook)(HWND);
typedef bool (*pfnUninstallHook)();
typedef void (*pfnUpdateMetrics)(int, int, int);

static HMODULE g_hHookDll = nullptr;
static pfnInstallHook g_InstallHook = nullptr;
static pfnUninstallHook g_UninstallHook = nullptr;
static pfnUpdateMetrics g_UpdateMetrics = nullptr;

void LoadInternalHook()
{
  if (!g_hHookDll)
  {
    g_hHookDll = LoadLibraryW(L"taskbar_hook.dll");
    if (g_hHookDll)
    {
      g_InstallHook = (pfnInstallHook)GetProcAddress(g_hHookDll, "InstallTaskbarHook");
      g_UninstallHook = (pfnUninstallHook)GetProcAddress(g_hHookDll, "UninstallTaskbarHook");
      g_UpdateMetrics = (pfnUpdateMetrics)GetProcAddress(g_hHookDll, "UpdateTaskbarMetrics");
    }
  }
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

  int sW = GetSystemMetrics(SM_CXSCREEN);
  int sH = GetSystemMetrics(SM_CYSCREEN);
  int winW = 940;
  int winH = 620;
  SetWindowPos(hWnd, nullptr, (sW - winW) / 2, (sH - winH) / 2, winW, winH, SWP_FRAMECHANGED | SWP_SHOWWINDOW);

  DWM_WINDOW_CORNER_PREFERENCE pref = DWMWCP_ROUND;
  DwmSetWindowAttribute(hWnd, DWMWA_WINDOW_CORNER_PREFERENCE, &pref, sizeof(pref));

  RECT frame = GetClientArea();
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view())
    return false;
  RegisterPlugins(flutter_controller_->engine());

  // Kanca DLL'ini hazırla
  LoadInternalHook();

  auto channel = std::make_unique<flutter::MethodChannel<>>(
      flutter_controller_->engine()->messenger(), "winricer/window_manager", &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler([](const flutter::MethodCall<> &call, std::unique_ptr<flutter::MethodResult<>> result)
                                {
    if (call.method_name() == "closeApp") {
      if (g_UninstallHook) g_UninstallHook();
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
    if (call.method_name() == "applyTaskbarHook") {
      const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
      if (args) {
        bool isActive = false;
        int height = 64;
        int radius = 18;
        int margin = 60;

        auto active_it = args->find(flutter::EncodableValue("isActive"));
        if (active_it != args->end() && std::holds_alternative<bool>(active_it->second)) isActive = std::get<bool>(active_it->second);
        auto h_it = args->find(flutter::EncodableValue("height"));
        if (h_it != args->end() && std::holds_alternative<double>(h_it->second)) height = (int)std::get<double>(h_it->second);
        auto r_it = args->find(flutter::EncodableValue("radius"));
        if (r_it != args->end() && std::holds_alternative<double>(r_it->second)) radius = (int)std::get<double>(r_it->second);
        auto m_it = args->find(flutter::EncodableValue("margin"));
        if (m_it != args->end() && std::holds_alternative<double>(m_it->second)) margin = (int)std::get<double>(m_it->second);

        HWND hTaskbar = FindWindowW(L"Shell_TrayWnd", nullptr);
        if (isActive) {
          if (g_InstallHook) g_InstallHook(hTaskbar);
          if (g_UpdateMetrics) g_UpdateMetrics(height, radius, margin);
        } else {
          if (g_UninstallHook) g_UninstallHook();
        }
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
  if (g_UninstallHook)
    g_UninstallHook();
  if (g_hHookDll)
  {
    FreeLibrary(g_hHookDll);
    g_hHookDll = nullptr;
  }
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