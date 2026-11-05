@echo off
rem Portfolio: removes the "pfopen:" link handler.
reg delete "HKCU\Software\Classes\pfopen" /f >nul 2>&1
rmdir /s /q "%LOCALAPPDATA%\PortfolioOpener" >nul 2>&1
echo Portfolio file opener removed.
echo.
pause
