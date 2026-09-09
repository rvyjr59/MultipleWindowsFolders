<#
    OpenFoldersAsTabs.ps1
    Opens a list of folders as TABS in a single File Explorer window (Windows 11).

    HOW TO USE:
    1. Edit the $Folders list below.
    2. Close any open File Explorer windows for best results.
    3. Right-click -> "Run with PowerShell", or double-click the .bat launcher.
    4. DON'T TOUCH the keyboard or mouse while it runs — it will tell you when it's done.

    This version uses longer delays and single-pass navigation for reliability.
#>

# ---- EDIT THIS LIST ----
$Folders = @(
    "$env:USERPROFILE\Downloads"
    "$env:USERPROFILE\OneDrive\ObsidianVault"
    "$env:USERPROFILE\OneDrive\ObsidianVault\Vault"
    "$env:USERPROFILE\OneDrive\ObsidianVault\Projects"
    # Add more folder paths here, one per line, in quotes
)
# -------------------------

Add-Type -AssemblyName System.Windows.Forms

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class WinAPI {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetClassName(IntPtr hWnd, System.Text.StringBuilder lpClassName, int nMaxCount);

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [DllImport("user32.dll")]
    public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();

    public const int SW_RESTORE = 9;
    public const int SW_SHOW = 5;

    public static System.Collections.Generic.List<IntPtr> GetExplorerWindows() {
        var result = new System.Collections.Generic.List<IntPtr>();
        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
            if (IsWindowVisible(hWnd)) {
                var sb = new System.Text.StringBuilder(256);
                GetClassName(hWnd, sb, sb.Capacity);
                if (sb.ToString() == "CabinetWClass") {
                    result.Add(hWnd);
                }
            }
            return true;
        }, IntPtr.Zero);
        return result;
    }

    public static void ForceForeground(IntPtr hWnd) {
        ShowWindow(hWnd, SW_RESTORE);
        ShowWindow(hWnd, SW_SHOW);

        IntPtr foreground = GetForegroundWindow();
        uint foreThread, appThread;
        GetWindowThreadProcessId(foreground, out foreThread);
        foreThread = GetWindowThreadProcessId(foreground, out foreThread);
        appThread = GetCurrentThreadId();

        if (foreThread != appThread) {
            AttachThreadInput(foreThread, appThread, true);
            SetForegroundWindow(hWnd);
            AttachThreadInput(foreThread, appThread, false);
        } else {
            SetForegroundWindow(hWnd);
        }
    }
}
"@

# Validate folders
$ValidFolders = @()
foreach ($f in $Folders) {
    if (Test-Path -Path $f -PathType Container) {
        $ValidFolders += $f
    }
}

if ($ValidFolders.Count -eq 0) { exit }

# Save clipboard
$savedClip = $null
try { $savedClip = Get-Clipboard -Raw -ErrorAction SilentlyContinue } catch {}

# Snapshot existing Explorer windows
$before = [WinAPI]::GetExplorerWindows()

# Open the first folder
Start-Process explorer.exe -ArgumentList "`"$($ValidFolders[0])`""

# Wait for the new Explorer window to appear
$targetHwnd = [IntPtr]::Zero
$deadline = (Get-Date).AddSeconds(8)
while ($targetHwnd -eq [IntPtr]::Zero -and (Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 300
    $after = [WinAPI]::GetExplorerWindows()
    $newOnes = $after | Where-Object { $before -notcontains $_ }
    if ($newOnes) {
        $targetHwnd = @($newOnes)[0]
    }
}

if ($targetHwnd -eq [IntPtr]::Zero) { exit }
Start-Sleep -Seconds 3

# Force focus
[WinAPI]::ForceForeground($targetHwnd)
Start-Sleep -Seconds 1

# Open remaining folders as tabs
for ($i = 1; $i -lt $ValidFolders.Count; $i++) {
    $folder = $ValidFolders[$i]
    # Put path on clipboard FIRST, before any UI interaction
    Set-Clipboard -Value $folder

    # Ensure focus
    [WinAPI]::ForceForeground($targetHwnd)
    Start-Sleep -Milliseconds 500

    # Ctrl+T to open new tab
    [System.Windows.Forms.SendKeys]::SendWait("^t")
    Start-Sleep -Seconds 3

    # Re-focus — the new tab steals internal focus
    [WinAPI]::ForceForeground($targetHwnd)
    Start-Sleep -Milliseconds 500

    # Alt+D is more reliable than Ctrl+L for focusing the address bar
    [System.Windows.Forms.SendKeys]::SendWait("%d")
    Start-Sleep -Milliseconds 800

    # Paste path
    [System.Windows.Forms.SendKeys]::SendWait("^v")
    Start-Sleep -Milliseconds 800

    # Verify paste landed — re-focus and try once more if needed
    [WinAPI]::ForceForeground($targetHwnd)
    Start-Sleep -Milliseconds 200

    # Enter to navigate
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Seconds 3

}

# Restore clipboard
if ($null -ne $savedClip) {
    try { Set-Clipboard -Value $savedClip -ErrorAction SilentlyContinue } catch {}
}

