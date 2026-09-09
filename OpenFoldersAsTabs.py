"""
OpenFoldersAsTabs.py
Opens a list of folders as TABS in a single File Explorer window (Windows 11).

REQUIRES: pip install pywin32

HOW TO USE:
1. Edit the FOLDERS list below.
2. Close all File Explorer windows (or use the .bat launcher which does it for you).
3. Run: python OpenFoldersAsTabs.py
4. DON'T TOUCH keyboard or mouse until it says "Done".
"""

import os
import subprocess
import time

import win32clipboard
import win32com.client
import win32gui
import win32con
import ctypes
from ctypes import wintypes

# ---- EDIT THIS LIST ----
_home = os.path.expandvars("%USERPROFILE%")
FOLDERS = [
    os.path.join(_home, "Downloads"),
    os.path.join(_home, "OneDrive", "ObsidianVault"),
    os.path.join(_home, "OneDrive", "ObsidianVault", "Vault"),
    os.path.join(_home, "OneDrive", "ObsidianVault", "Projects"),
    # Add more folder paths here, one per line
]
# -------------------------


user32 = ctypes.windll.user32
kernel32 = ctypes.windll.kernel32


def get_explorer_windows():
    """Return HWNDs of all visible File Explorer windows."""
    handles = []
    def callback(hwnd, _):
        if win32gui.IsWindowVisible(hwnd):
            if win32gui.GetClassName(hwnd) == "CabinetWClass":
                handles.append(hwnd)
        return True
    win32gui.EnumWindows(callback, None)
    return handles


def force_foreground(hwnd):
    """Aggressively bring a window to the front."""
    if not hwnd:
        return
    win32gui.ShowWindow(hwnd, win32con.SW_RESTORE)
    win32gui.ShowWindow(hwnd, win32con.SW_SHOW)

    fore = user32.GetForegroundWindow()
    fore_thread = user32.GetWindowThreadProcessId(fore, None)
    app_thread = kernel32.GetCurrentThreadId()

    if fore_thread != app_thread:
        user32.AttachThreadInput(fore_thread, app_thread, True)
        user32.SetForegroundWindow(hwnd)
        user32.AttachThreadInput(fore_thread, app_thread, False)
    else:
        user32.SetForegroundWindow(hwnd)


def set_clipboard_text(text):
    win32clipboard.OpenClipboard()
    try:
        win32clipboard.EmptyClipboard()
        win32clipboard.SetClipboardText(text, win32clipboard.CF_UNICODETEXT)
    finally:
        win32clipboard.CloseClipboard()


def get_clipboard_text():
    try:
        win32clipboard.OpenClipboard()
        try:
            return win32clipboard.GetClipboardData(win32clipboard.CF_UNICODETEXT)
        except TypeError:
            return None
        finally:
            win32clipboard.CloseClipboard()
    except Exception:
        return None


def main():
    valid_folders = [f for f in FOLDERS if os.path.isdir(f)]

    if not valid_folders:
        return

    saved_clip = get_clipboard_text()
    shell = win32com.client.Dispatch("WScript.Shell")

    # Snapshot existing Explorer windows
    before = get_explorer_windows()

    # Open the first folder
    subprocess.Popen(["explorer.exe", valid_folders[0]])

    # Wait for the new window
    target_hwnd = None
    deadline = time.time() + 8
    while target_hwnd is None and time.time() < deadline:
        time.sleep(0.3)
        after = get_explorer_windows()
        new_ones = [h for h in after if h not in before]
        if new_ones:
            target_hwnd = new_ones[0]

    if target_hwnd is None:
        return
    time.sleep(3)

    force_foreground(target_hwnd)
    time.sleep(1)

    # Open remaining folders as tabs
    for folder in valid_folders[1:]:
        # Set clipboard BEFORE any UI interaction
        set_clipboard_text(folder)

        # Ensure focus
        force_foreground(target_hwnd)
        time.sleep(0.5)

        # Ctrl+T for new tab
        shell.SendKeys("^t")
        time.sleep(3)

        # Re-focus
        force_foreground(target_hwnd)
        time.sleep(0.5)

        # Alt+D to focus address bar (more reliable than Ctrl+L)
        shell.SendKeys("%d")
        time.sleep(0.8)

        # Paste
        shell.SendKeys("^v")
        time.sleep(0.8)

        # Re-focus before Enter
        force_foreground(target_hwnd)
        time.sleep(0.2)

        # Navigate
        shell.SendKeys("{ENTER}")
        time.sleep(3)

    # Restore clipboard
    if saved_clip is not None:
        try:
            set_clipboard_text(saved_clip)
        except Exception:
            pass



if __name__ == "__main__":
    main()

    # Close the calling console window (works whether launched from .bat or terminal)
    console_hwnd = kernel32.GetConsoleWindow()
    if console_hwnd:
        win32gui.PostMessage(console_hwnd, win32con.WM_CLOSE, 0, 0)
