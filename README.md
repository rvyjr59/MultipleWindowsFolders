# MultipleWindowsFolders

Open a list of folders as **tabs in a single File Explorer window** on Windows 11 — with one double-click.

## Quick Start

1. Open `OpenFoldersAsTabs.py` and edit the folder list at the top
2. Double-click **`OpenFoldersAsTabs_Python.bat`**
3. Don't touch your keyboard or mouse until the Explorer window finishes loading all tabs (~6 sec per tab)

That's it. The console window closes automatically when done.

## What's Included

| File | What it does |
|------|-------------|
| `OpenFoldersAsTabs.py` | Main script. Opens folders as tabs in one Explorer window. |
| `OpenFoldersAsTabs_Python.bat` | Double-click launcher for the `.py`. |
| `archive-ps1/` | Archived PowerShell approach (`.ps1` scripts and their `.bat` launchers). |

## Editing the Folder List

Open `OpenFoldersAsTabs.py` and edit the `FOLDERS` list:

```python
_home = os.path.expandvars("%USERPROFILE%")
FOLDERS = [
    os.path.join(_home, "Downloads"),
    os.path.join(_home, "OneDrive", "ObsidianVault"),
    os.path.join(_home, "OneDrive", "ObsidianVault", "Vault"),
    os.path.join(_home, "OneDrive", "ObsidianVault", "Projects"),
]
```

Paths use `%USERPROFILE%` via `os.path.expandvars` so the script is portable across accounts.

## Requirements

- **Windows 11** — Explorer tabs are a Windows 11 feature. On Windows 10 you'll get separate windows instead.
- **Python 3** with the `pywin32` package:
  ```
  pip install pywin32
  ```

## How It Works

Windows has no command-line API for opening Explorer tabs, so the script simulates it:

1. Opens the first folder in a normal Explorer window
2. Detects the new window by its handle (HWND) — comparing window lists before/after launch
3. For each additional folder:
   - Sets the clipboard to the folder path
   - Sends **Ctrl+T** → new tab
   - Sends **Alt+D** → focuses the address bar
   - Sends **Ctrl+V** → pastes the path
   - Sends **Enter** → navigates
4. Restores your original clipboard contents when done
5. Closes the launcher's console window automatically

Focus is enforced between each step using Win32 `AttachThreadInput` + `SetForegroundWindow`, which is more reliable than basic `SetForegroundWindow` alone (Windows blocks background apps from stealing focus by default).

## Troubleshooting

| Problem | Fix |
|---------|-----|
| A tab opens but shows "Home" instead of the folder | Increase the `time.sleep` delays in the script. The 3-second pauses after Ctrl+T and Enter are the most important ones. |
| The script opens separate windows instead of tabs | Make sure you're on Windows 11 with Explorer tabs enabled (it's on by default). |
| Nothing happens when double-clicking the `.bat` | Right-click → Run as administrator, or run the Python command manually. |
| Python errors on import | Run `pip install pywin32` first. |

## Tips

- **Pin the `.bat` to your taskbar** or Start menu for one-click access
- **Add more folder lists**: duplicate the `.py` and `.bat` with different names and folder lists for different workflows (e.g., `WorkFolders.bat`, `ProjectFolders.bat`)
- **Don't interact** with the keyboard or mouse while the script runs — it uses simulated keystrokes that need Explorer to stay in focus
