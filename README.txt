MultipleWindowsFolders
======================

Open a list of folders as tabs in a single File Explorer window on Windows 11 — with one double-click.


QUICK START
-----------

1. Open OpenFoldersAsTabs.py and edit the folder list at the top
2. Right-click "OpenFoldersAsTabs_Python.ps1" -> Run with PowerShell
3. Don't touch your keyboard or mouse until the Explorer window finishes loading all tabs (~9 sec per tab)

That's it. The console window closes automatically when done.


WHAT'S INCLUDED
---------------

  OpenFoldersAsTabs.py          Main script. Opens folders as tabs in one Explorer window.
  OpenFoldersAsTabs_Python.ps1  Launcher for the .py. Finds a working interpreter and
                                checks pywin32 before running.
  archive-ps1/                  Archived PowerShell approach (.ps1 scripts and their .bat launchers).


EDITING THE FOLDER LIST
-----------------------

Open OpenFoldersAsTabs.py and edit the FOLDERS list:

    _home = os.path.expandvars("%USERPROFILE%")
    FOLDERS = [
        os.path.join(_home, "Downloads"),
        os.path.join(_home, "OneDrive", "ObsidianVault"),
        os.path.join(_home, "OneDrive", "ObsidianVault", "Vault"),
        os.path.join(_home, "OneDrive", "ObsidianVault", "Projects"),
    ]

Paths use %USERPROFILE% via os.path.expandvars so the script is
portable across accounts.


REQUIREMENTS
------------

- Windows 11 — Explorer tabs are a Windows 11 feature. On Windows 10 you'll get separate windows instead.
- Python 3 with the pywin32 package.

Install pywin32 into the SAME interpreter the launcher reports, using its full path:

    & 'C:\Path\To\python.exe' -m pip install pywin32

A bare "pip install pywin32" can land in a different interpreter than the one that
actually runs the script — a common cause of "it says it's installed but the import
still fails."


HOW THE LAUNCHER PICKS PYTHON
-----------------------------

The launcher does NOT trust PATH order. The Microsoft Store stub at
%LOCALAPPDATA%\Microsoft\WindowsApps\python.exe BLOCKS FOREVER waiting on input
instead of failing, so when it wins PATH order the script appears to do nothing
at all — no error, no window.

Search order:

1. Every "python" on PATH, with anything under \WindowsApps\ filtered out
2. The "py -3" launcher, which never resolves to the stub
3. Known install locations — C:\Python3xx, %LOCALAPPDATA%\Programs\Python\Python3xx,
   %ProgramFiles%\Python3xx

Install locations legitimately differ between machines (a drive-root install vs. a
winget per-user install), so the launcher probes both rather than requiring them to
match.

It then verifies the pywin32 imports BEFORE launching and, on failure, prints the
exact pip install command for that specific interpreter. If no real interpreter
exists, it exits with an install command instead of hanging.


HOW IT WORKS
------------

Windows has no command-line API for opening Explorer tabs, so the script simulates it:

1. Opens the first folder in a normal Explorer window
2. Detects the new window by its handle (HWND) — comparing window lists before/after launch
3. For each additional folder:
   - Sets the clipboard to the folder path
   - Sends Ctrl+T        -> new tab
   - Sends Alt+D         -> focuses the address bar
   - Sends Ctrl+V        -> pastes the path
   - Sends Enter         -> navigates
4. Restores your original clipboard contents when done
5. Closes the launcher's console window automatically

Focus is enforced between each step using Win32 AttachThreadInput + SetForegroundWindow, which is more reliable than basic SetForegroundWindow alone (Windows blocks background apps from stealing focus by default).


TROUBLESHOOTING
---------------

- A tab opens but shows "Home" instead of the folder:
  Increase the time.sleep delays in the script. The 3-second pauses after Ctrl+T and Enter are the most important ones.

- Tabs land on "Home" only SOMETIMES, for some folders:
  Not a timing problem — the target is likely a cloud-only OneDrive placeholder that
  Explorer can't resolve in time. Set the folder to "Always keep on this device".

- The script opens separate windows instead of tabs:
  Make sure you're on Windows 11 with Explorer tabs enabled (it's on by default).

- Nothing happens when running the launcher:
  The launcher reports which interpreter it picked and why it stopped. If it exits
  silently, check the execution policy: Get-ExecutionPolicy -Scope CurrentUser
  should be RemoteSigned.

- Python errors on import:
  Install pywin32 into the interpreter the launcher names, by full path (see REQUIREMENTS).


TIPS
----

- Add more folder lists: duplicate the .py and .ps1 with different names and folder lists for different workflows (e.g., WorkFolders.ps1, ProjectFolders.ps1).
- Don't interact with the keyboard or mouse while the script runs — it uses simulated keystrokes that need Explorer to stay in focus.
