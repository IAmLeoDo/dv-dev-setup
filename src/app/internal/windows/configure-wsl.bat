@echo off
setlocal DisableDelayedExpansion
call "%~dp0change-mode.bat" %*
if errorlevel 1 exit /b 2
set "Config=%~dp0..\..\config.ini"
set "Target=%USERPROFILE%\.wslconfig"
set "Render="
set "Memory="
set "Swap="
set "Forwarding="
set "Reclaim="
call :readConfig "%Config%"
if errorlevel 1 goto failed
if not defined DV_CONFIG goto validate
call :readConfig "%DV_CONFIG%"
if errorlevel 1 goto failed
:validate
if not defined Memory goto invalid
if not defined Swap goto invalid
if not defined Forwarding goto invalid
if not defined Reclaim goto invalid
if "%DvApply%"=="true" goto execute
echo Plan: write "%Target%" with these validated WSL settings:
echo   memory=%Memory%, swap=%Swap%
echo   localhostForwarding=%Forwarding%, autoMemoryReclaim=%Reclaim%
echo Existing configuration is backed up after confirmation when a change is needed.
echo Preview only. Nothing changed. Run dev.bat setup 3 --apply to execute.
exit /b 0
:execute
fltmc >nul 2>&1
if not errorlevel 1 (
    echo Run dev.bat setup 3 --apply from your normal development account, not as administrator.
    exit /b 1
)
:temporary
set "Render=%TEMP%\dv-wsl-%RANDOM%-%RANDOM%.tmp"
if exist "%Render%" goto temporary
(
    echo [wsl2]
    echo memory=%Memory%
    echo swap=%Swap%
    echo localhostForwarding=%Forwarding%
    echo.
    echo [experimental]
    echo autoMemoryReclaim=%Reclaim%
) > "%Render%"
if errorlevel 1 goto failed
if not exist "%Target%" goto confirm
fc /b "%Render%" "%Target%" >nul 2>&1
if not errorlevel 1 (
    echo WSL configuration already matches; preserving it.
    goto done
)
:confirm
echo This replaces "%Target%" using config.ini WSL settings.
echo Any existing file will be backed up first.
choice /c YN /n /m "Apply WSL configuration? [Y/N] "
if errorlevel 2 goto done
if errorlevel 1 goto apply
goto failed
:apply
if not exist "%Target%" goto write
:backup
set "Backup=%Target%.backup.%RANDOM%-%RANDOM%"
if exist "%Backup%" goto backup
copy /b "%Target%" "%Backup%" >nul
if errorlevel 1 goto failed
echo Backup: "%Backup%"
:write
copy /b /y "%Render%" "%Target%" >nul
if errorlevel 1 goto failed
echo Configuration saved. Save WSL work, then run wsl --shutdown manually to apply.
:done
if defined Render del /q "%Render%" >nul 2>&1
exit /b 0
:readConfig
if not exist "%~1" (
    echo Configuration file not found: "%~1"
    exit /b 1
)
rem Normalize selected lines through a pipe before /x matching: config.ini may
rem use LF in both source and bundles. Untrusted lines remain data, never code.
findstr /b /c:"memory=" "%~1" >nul
if not errorlevel 1 set "Memory="
for /f "tokens=1,* delims==" %%K in ('findstr /b /c:"memory=" "%~1" ^| find /v "" ^| findstr /r /x /c:"memory=[1-9][0-9]*GB" /c:"memory=[1-9][0-9]*MB"') do set "Memory=%%L"
findstr /b /c:"swap=" "%~1" >nul
if not errorlevel 1 set "Swap="
for /f "tokens=1,* delims==" %%K in ('findstr /b /c:"swap=" "%~1" ^| find /v "" ^| findstr /r /x /c:"swap=[1-9][0-9]*GB" /c:"swap=[1-9][0-9]*MB" /c:"swap=0"') do set "Swap=%%L"
findstr /b /c:"localhostForwarding=" "%~1" >nul
if not errorlevel 1 set "Forwarding="
for /f "tokens=1,* delims==" %%K in ('findstr /b /c:"localhostForwarding=" "%~1" ^| find /v "" ^| findstr /l /x /c:"localhostForwarding=true" /c:"localhostForwarding=false"') do set "Forwarding=%%L"
findstr /b /c:"autoMemoryReclaim=" "%~1" >nul
if not errorlevel 1 set "Reclaim="
for /f "tokens=1,* delims==" %%K in ('findstr /b /c:"autoMemoryReclaim=" "%~1" ^| find /v "" ^| findstr /l /x /c:"autoMemoryReclaim=gradual" /c:"autoMemoryReclaim=dropCache" /c:"autoMemoryReclaim=disabled"') do set "Reclaim=%%L"
exit /b 0
:invalid
echo Invalid WSL config. Use memory in MB/GB, swap in MB/GB or 0, true/false, gradual/dropCache/disabled.
:failed
if defined Render del /q "%Render%" >nul 2>&1
exit /b 1
