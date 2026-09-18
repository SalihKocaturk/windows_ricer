#define TASKBAR_HOOK_EXPORTS
#include "taskbar_hook.h"
#include <dwmapi.h>

static HHOOK g_hHook = nullptr;
static HWND g_hTaskbar = nullptr;
static WNDPROC g_OriginalWndProc = nullptr;

static int g_Height = 60;
static int g_Radius = 16;
static int g_Margin = 40;

// Görev Çubuğunu Subclass edip mesajlarını içeriden yakalayan fonksiyon
LRESULT CALLBACK TaskbarSubclassProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    // WinRicer'dan gelen canlı ayar mesajları
    if (uMsg == WM_WINRICER_SET_SIZE)
    {
        g_Height = (int)wParam;
        RECT rc;
        GetWindowRect(hWnd, &rc);
        int w = rc.right - rc.left;
        HRGN rgn = CreateRoundRectRgn(g_Margin, 0, w - g_Margin, g_Height, g_Radius * 2, g_Radius * 2);
        SetWindowRgn(hWnd, rgn, TRUE);
        SetWindowPos(hWnd, nullptr, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
        return 0;
    }

    // Windows'un görev çubuğunu varsayılan 48px'e zorlamasını engelle
    if (uMsg == WM_WINDOWPOSCHANGING)
    {
        WINDOWPOS *pos = (WINDOWPOS *)lParam;
        if (!(pos->flags & SWP_NOSIZE) && g_Height > 48)
        {
            pos->cy = g_Height; // Boyuna yüksekliği WinRicer'ın belirlediği boyuta kilitler
        }
    }

    return CallWindowProc(g_OriginalWndProc, hWnd, uMsg, wParam, lParam);
}

// Windows Mesaj Kancası
LRESULT CALLBACK GetMsgProc(int code, WPARAM wParam, LPARAM lParam)
{
    return CallNextHookEx(g_hHook, code, wParam, lParam);
}

TASKBAR_HOOK_API bool InstallTaskbarHook(HWND hTaskbar)
{
    if (!hTaskbar)
        return false;
    g_hTaskbar = hTaskbar;

    DWORD threadId = GetWindowThreadProcessId(hTaskbar, nullptr);
    if (!threadId)
        return false;

    HMODULE hModule = nullptr;
    GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                       (LPCWSTR)&InstallTaskbarHook, &hModule);

    g_hHook = SetWindowsHookExW(WH_GETMESSAGE, GetMsgProc, hModule, threadId);
    if (!g_hHook)
        return false;

    // Görev çubuğunun pencere prosedürünü güvenle subclass yap
    g_OriginalWndProc = (WNDPROC)SetWindowLongPtrW(hTaskbar, GWLP_WNDPROC, (LONG_PTR)TaskbarSubclassProc);

    return true;
}

TASKBAR_HOOK_API bool UninstallTaskbarHook()
{
    if (g_hTaskbar && g_OriginalWndProc)
    {
        SetWindowLongPtrW(g_hTaskbar, GWLP_WNDPROC, (LONG_PTR)g_OriginalWndProc);
        g_OriginalWndProc = nullptr;
        SetWindowRgn(g_hTaskbar, NULL, TRUE);
    }
    if (g_hHook)
    {
        UnhookWindowsHookEx(g_hHook);
        g_hHook = nullptr;
    }
    return true;
}

TASKBAR_HOOK_API void UpdateTaskbarMetrics(int height, int radius, int margin)
{
    if (g_hTaskbar)
    {
        g_Height = height;
        g_Radius = radius;
        g_Margin = margin;
        PostMessageW(g_hTaskbar, WM_WINRICER_SET_SIZE, (WPARAM)height, (LPARAM)radius);
    }
}