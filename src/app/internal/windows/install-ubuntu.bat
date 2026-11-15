@echo off
setlocal
fltmc >nul 2>&1
if not errorlevel 1 (
    echo Run dev.bat setup 2 from a normal CMD under your development account, not as administrator.
    exit /b 1
)
where wsl.exe >nul 2>&1
if errorlevel 1 (
    echo WSL unavailable. Complete dev.bat setup 1 and restart first.
    exit /b 1
)
rem Query registrations for the current user; never reinstall an existing distro.
for /f "delims=" %%K in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Lxss" 2^>nul') do (
    reg query "%%K" /v DistributionName 2>nul | findstr /r /c:"REG_SZ *Ubuntu-24.04$" >nul
    if not errorlevel 1 goto exists
)
wsl.exe --set-default-version 2
if errorlevel 1 exit /b %errorlevel%
wsl.exe --install --distribution Ubuntu-24.04 --no-launch
if errorlevel 1 exit /b %errorlevel%
goto next
:exists
echo Ubuntu-24.04 already registered; preserving it.
:next
echo Run: wsl -d Ubuntu-24.04
echo On first launch, create your Linux user and password.
echo Then run dev.bat setup 3. Check WSL version with dev.bat check.
exit /b 0
