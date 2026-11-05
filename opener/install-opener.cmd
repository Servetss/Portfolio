@echo off
rem Portfolio: installs the "pfopen:" link handler for the current Windows user (no admin rights needed).
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText('%~f0',[Text.Encoding]::UTF8); Invoke-Expression $s.Substring($s.IndexOf('#PS-'+'BEGIN'))"
echo.
pause
exit /b
#PS-BEGIN
$ErrorActionPreference = 'Stop'
$dir = Join-Path $env:LOCALAPPDATA 'PortfolioOpener'
$ps1 = Join-Path $dir 'open.ps1'

# The handler. It only opens files and folders on the computer's drives (C:\, D:\, network drive letters).
# Programs and scripts are never started: for those it opens the folder that holds them.
$handler = @'
param([string]$Link)
Add-Type -AssemblyName System.Windows.Forms
function Say([string]$text) { [void][System.Windows.Forms.MessageBox]::Show($text, 'Портфоліо команди') }
$p = [string]$Link
$p = $p -replace '^pfopen:(//)?', ''
try { $p = [uri]::UnescapeDataString($p) } catch {}
$p = $p.Trim().Trim('"').Replace('/', '\')
if ($p -notmatch '^[A-Za-z]:\\') { Say "Відкриваються лише файли й папки на дисках цього комп'ютера (C:\, D:\ …).`n`n$p"; exit }
if (Test-Path -LiteralPath $p -PathType Container) { Invoke-Item -LiteralPath $p; exit }
if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { Say "Файл не знайдено. Можливо, його перемістили або перейменували:`n`n$p"; exit }
$risky = @('.exe','.com','.bat','.cmd','.ps1','.psm1','.psd1','.vbs','.vbe','.js','.jse','.wsf','.wsh','.msi','.msp','.mst','.scr','.hta','.lnk','.url','.reg','.jar','.cpl','.dll','.ocx','.sys','.inf','.msc','.pif','.scf','.application','.appref-ms','.appx','.msix','.settingcontent-ms','.library-ms','.gadget','.chm','.iso','.img','.vhd','.vhdx')
$ext = [IO.Path]::GetExtension($p).ToLowerInvariant()
if ($ext -eq '' -or $risky -contains $ext) { $i = $p.LastIndexOf('\'); Invoke-Item -LiteralPath $(if ($i -le 2) { $p.Substring(0, 3) } else { $p.Substring(0, $i) }); exit }
Invoke-Item -LiteralPath $p
'@

New-Item -ItemType Directory -Force -Path $dir | Out-Null
[IO.File]::WriteAllText($ps1, $handler, (New-Object System.Text.UTF8Encoding $true))

$sys = [Environment]::GetFolderPath('System')
$cmd = '"' + (Join-Path $sys 'conhost.exe') + '" --headless "' + (Join-Path $sys 'WindowsPowerShell\v1.0\powershell.exe') + '" -NoProfile -ExecutionPolicy Bypass -File "' + $ps1 + '" "%1"'
$key = 'HKCU:\Software\Classes\pfopen'
New-Item -Path $key -Force | Out-Null
Set-ItemProperty -Path $key -Name '(Default)' -Value 'URL:Портфоліо — відкрити файл'
New-ItemProperty -Path $key -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
New-Item -Path "$key\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "$key\shell\open\command" -Name '(Default)' -Value $cmd

Write-Host ''
Write-Host 'Готово: відкривач файлів для «Портфоліо команди» встановлено.' -ForegroundColor Green
Write-Host 'Тепер посилання на файли з комп''ютера відкриваються кліком.'
Write-Host 'Браузер при першому кліку спитає дозволу: поставте галочку «Завжди дозволяти» і натисніть «Відкрити».'
Write-Host "Обробник лежить тут: $ps1"
