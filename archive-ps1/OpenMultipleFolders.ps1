<#
    OpenMultipleFolders.ps1
    Opens a list of folders, each in its own File Explorer window.

    HOW TO USE:
    1. Edit the $Folders list below - add, remove, or change paths as needed.
       Each path goes on its own line, in quotes.
    2. Save this file.
    3. Run it by right-clicking and choosing "Run with PowerShell",
       or from a PowerShell prompt:  .\OpenMultipleFolders.ps1
#>

# ---- EDIT THIS LIST ----
$Folders = @(
    "C:\Users\yolan\Documents"
    "C:\Users\yolan\Downloads"
    "C:\Users\yolan\OneDrive"
    # Add more folder paths here, one per line, in quotes
)
# -------------------------

foreach ($folder in $Folders) {
    if (Test-Path -Path $folder -PathType Container) {
        Start-Process explorer.exe -ArgumentList "`"$folder`""
        Start-Sleep -Milliseconds 200   # small pause so windows open in order
    }
    else {
        Write-Warning "Folder not found, skipping: $folder"
    }
}
