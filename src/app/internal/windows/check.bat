@echo off
setlocal
echo === Windows ===
ver
echo Account: %USERNAME%
fltmc >nul 2>&1
if errorlevel 1 (echo Administrator: no) else (echo Administrator: yes)
if exist "%USERPROFILE%\.wslconfig" (echo WSL profile config: present) else (echo WSL profile config: missing)
echo === WSL ===
where wsl.exe >nul 2>&1
if errorlevel 1 (
    echo WSL unavailable. Use dev.bat setup 1 as administrator first.
    exit /b 1
)
wsl.exe --version
wsl.exe --status
wsl.exe --list --verbose
exit /b %errorlevel%
