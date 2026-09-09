@echo off
REM ============================================================
REM  OpenMultipleFolders.bat
REM  Opens a list of folders, each in its own File Explorer window.
REM
REM  HOW TO USE:
REM  1. Edit the folder paths below - add, remove, or change lines
REM     as needed. Each line opens one folder, and is skipped
REM     automatically if that folder doesn't exist.
REM  2. Save this file.
REM  3. Double-click to run.
REM ============================================================

if exist "C:\Users\yolan\Documents" start "" explorer "C:\Users\yolan\Documents"
if exist "C:\Users\yolan\Downloads" start "" explorer "C:\Users\yolan\Downloads"
if exist "C:\Users\yolan\OneDrive" start "" explorer "C:\Users\yolan\OneDrive"

REM Add more lines like above, one per folder:
REM if exist "C:\path\to\folder" start "" explorer "C:\path\to\folder"
