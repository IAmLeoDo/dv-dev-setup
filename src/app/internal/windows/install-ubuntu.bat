@echo off
setlocal DisableDelayedExpansion
call "%~dp0change-mode.bat" %*
if errorlevel 1 exit /b 2
if "%DvApply%"=="true" goto execute
echo Plan: set the default WSL version to 2 and install Ubuntu-24.04 if not registered.
echo Existing Ubuntu registrations are preserved; the installer does not launch the distro.
echo Preview only. Nothing changed. Run dev.bat setup 2 --apply to execute.
exit /b 0
:execute
fltmc >nul 2>&1
if not errorlevel 1 (
    echo Run dev.bat setup 2 --apply from a normal CMD under your development account, not as administrator.
    exit /b 1
)
where wsl.exe >nul 2>&1
if errorlevel 1 (
    echo WSL unavailable. Complete dev.bat setup 1 --apply and restart first.
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
echo Then run dev.bat setup 3 --apply. Check WSL version with dev.bat check.
exit /b 0
