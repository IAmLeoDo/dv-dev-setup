@echo off
setlocal DisableDelayedExpansion
call "%~dp0change-mode.bat" %*
if errorlevel 1 exit /b 2
if "%DvApply%"=="true" goto execute
echo Plan: enable Windows Subsystem for Linux and Virtual Machine Platform without rebooting.
echo Administrator access is required only with --apply.
echo Preview only. Nothing changed. Run dev.bat setup 1 --apply to execute.
exit /b 0
:execute
fltmc >nul 2>&1
if errorlevel 1 (
    echo Open CMD as administrator, then run dev.bat setup 1 --apply again.
    echo Return to your normal development account for steps 2 and 3.
    exit /b 1
)
set "WindowsBuild="
for /f "tokens=3" %%B in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber 2^>nul') do set "WindowsBuild=%%B"
if not defined WindowsBuild (
    echo Cannot determine Windows build.
    exit /b 1
)
if %WindowsBuild% LSS 22000 (
    echo Windows 11 or later is required.
    exit /b 1
)
set "RestartRequired=0"
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
set "Result=%errorlevel%"
if "%Result%"=="3010" set "RestartRequired=1"
if not "%Result%"=="0" if not "%Result%"=="3010" exit /b %Result%
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
set "Result=%errorlevel%"
if "%Result%"=="3010" set "RestartRequired=1"
if not "%Result%"=="0" if not "%Result%"=="3010" exit /b %Result%
if "%RestartRequired%"=="1" (
    echo Restart required. Save work and reboot manually, then run dev.bat setup 2 --apply as your development user.
    exit /b 3010
)
echo WSL features enabled. Continue with dev.bat setup 2 --apply as your development user.
exit /b 0
