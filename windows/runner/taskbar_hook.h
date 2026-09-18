#pragma once
#include <windows.h>

#ifdef TASKBAR_HOOK_EXPORTS
#define TASKBAR_HOOK_API __declspec(dllexport)
#else
#define TASKBAR_HOOK_API __declspec(dllimport)
#endif

// WinRicer ile DLL arasındaki özel mesaj kodları
#define WM_WINRICER_SET_SIZE (WM_USER + 401)
#define WM_WINRICER_SET_RADIUS (WM_USER + 402)
#define WM_WINRICER_SET_GLASS (WM_USER + 403)

extern "C"
{
    TASKBAR_HOOK_API bool InstallTaskbarHook(HWND hTaskbar);
    TASKBAR_HOOK_API bool UninstallTaskbarHook();
    TASKBAR_HOOK_API void UpdateTaskbarMetrics(int height, int radius, int margin);
}