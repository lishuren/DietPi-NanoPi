Param(
    [string]$Label = "usbdata"
)

# Safe Windows helper to format a removable drive as exFAT for cross-platform use.
# Prompts for a removable volume selection and confirms before formatting.

Write-Host "Listing removable volumes..." -ForegroundColor Cyan
$removables = Get-Volume | Where-Object { $_.DriveType -eq 'Removable' }
if (-not $removables) {
    Write-Host "No removable volumes detected." -ForegroundColor Yellow
    exit 1
}

$i = 0
$removables | ForEach-Object {
    $i++
    Write-Host ("[{0}] Letter={1} Label={2} FS={3} Size={4} Mounted={5}" -f $i, $_.DriveLetter, $_.FileSystemLabel, $_.FileSystem, $_.Size, $_.DriveLetter)
}

$selection = Read-Host "Enter selection number to format as exFAT"
if (-not ($selection -as [int]) -or $selection -lt 1 -or $selection -gt $removables.Count) {
    Write-Host "Invalid selection." -ForegroundColor Red
    exit 1
}

$target = $removables[$selection - 1]
Write-Host ("Selected drive: {0}: Label={1} FS={2}" -f $target.DriveLetter, $target.FileSystemLabel, $target.FileSystem) -ForegroundColor Cyan
Write-Host "WARNING: This will ERASE all data on $($target.DriveLetter):" -ForegroundColor Red
$confirm = Read-Host "Type YES to confirm"
if ($confirm -ne "YES") {
    Write-Host "Aborted." -ForegroundColor Yellow
    exit 1
}

Write-Host "Formatting $($target.DriveLetter): as exFAT with label '$Label'..." -ForegroundColor Green
Format-Volume -DriveLetter $target.DriveLetter -FileSystem exFAT -NewFileSystemLabel $Label -Confirm:$false -Force
Write-Host "Format complete." -ForegroundColor Green
