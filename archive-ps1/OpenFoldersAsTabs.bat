@echo off
REM ============================================================
REM  OpenFoldersAsTabs.bat
REM  Closes any open Explorer windows, then opens the folder
REM  list from the .ps1 as tabs in a single window.
REM ============================================================
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 1 /nobreak >nul
start explorer.exe
timeout /t 2 /nobreak >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0OpenFoldersAsTabs.ps1"
