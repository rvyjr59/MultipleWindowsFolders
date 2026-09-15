# Launch OpenFoldersAsTabs.py
# Requires Python and the pywin32 package (pip install pywin32).
# Edit the folder list inside the .py file, not here.
#
# Picks the interpreter deliberately rather than trusting PATH order, because
# the Microsoft Store stub (AppData\Local\Microsoft\WindowsApps\python.exe)
# BLOCKS FOREVER waiting on input instead of failing, which looks like the
# script doing nothing. Search order:
#   1. any non-stub "python" already on PATH
#   2. the py launcher (py -3)
#   3. known per-machine install locations - the three laptops differ:
#      C:\Python314 on the HP, %LOCALAPPDATA%\Programs\Python\... on the Dell

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$pyScript  = Join-Path $scriptDir "OpenFoldersAsTabs.py"

if (-not (Test-Path $pyScript)) {
    Write-Host "Python script not found: $pyScript" -ForegroundColor Red
    exit 1
}

function Test-IsStoreStub {
    param([string]$Path)
    return $Path -match '\\WindowsApps\\'
}

# ---- 1. Real interpreters already on PATH (stub excluded) ----
$candidates = @(
    Get-Command python -All -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Source |
        Where-Object { -not (Test-IsStoreStub $_) }
)

# ---- 2. The py launcher, which never resolves to the stub ----
$pyLauncher = Get-Command py -ErrorAction SilentlyContinue
$usePyLauncher = $false

# ---- 3. Known install locations on these machines ----
$candidates += @(
    "C:\Python314\python.exe"
    "C:\Python313\python.exe"
    "C:\Python312\python.exe"
    "$env:LOCALAPPDATA\Programs\Python\Python314\python.exe"
    "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe"
    "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
    "$env:ProgramFiles\Python314\python.exe"
    "$env:ProgramFiles\Python313\python.exe"
) | Where-Object { Test-Path $_ }

$pythonExe = $candidates | Select-Object -First 1

if (-not $pythonExe -and $pyLauncher) {
    $pythonExe = $pyLauncher.Source
    $usePyLauncher = $true
}

if (-not $pythonExe) {
    Write-Host "No real Python interpreter found on this machine." -ForegroundColor Red
    Write-Host "The Microsoft Store stub does not count - it hangs instead of running." -ForegroundColor Yellow
    Write-Host "Install Python, then re-run:" -ForegroundColor Yellow
    Write-Host "    winget install -e --id Python.Python.3.14" -ForegroundColor Cyan
    exit 1
}

Write-Host "Using interpreter: $pythonExe" -ForegroundColor DarkGray

# ---- Verify pywin32 before launching ----
# The .py imports win32clipboard/win32com.client/win32gui/win32con. Without
# pywin32 it dies on import with a traceback that looks like a script bug.
# pywin32 is per-machine AND per-interpreter, so it has to be checked here.
$importTest = if ($usePyLauncher) {
    & $pythonExe -3 -c "import win32clipboard,win32com.client,win32gui,win32con;print('pywin32ok')" 2>&1
} else {
    & $pythonExe -c "import win32clipboard,win32com.client,win32gui,win32con;print('pywin32ok')" 2>&1
}

if (($importTest -join ' ') -notmatch 'pywin32ok') {
    Write-Host "pywin32 is missing for this interpreter." -ForegroundColor Red
    Write-Host "Install it into this exact interpreter:" -ForegroundColor Yellow
    if ($usePyLauncher) {
        Write-Host "    py -3 -m pip install pywin32" -ForegroundColor Cyan
    } else {
        Write-Host "    & '$pythonExe' -m pip install pywin32" -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "Reported error:" -ForegroundColor DarkGray
    Write-Host ($importTest -join [Environment]::NewLine) -ForegroundColor DarkGray
    exit 1
}

# ---- Launch ----
if ($usePyLauncher) {
    & $pythonExe -3 $pyScript
} else {
    & $pythonExe $pyScript
}
