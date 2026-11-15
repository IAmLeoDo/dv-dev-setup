@echo off
setlocal
set "DvExitCode=0"
if not "%~3"=="" goto invalid
if "%~1"=="" goto default
if "%~1"=="menu" goto menu
if "%~1"=="help" goto help
if "%~1"=="--help" goto help
if "%~1"=="--version" goto version
if "%~1"=="version" goto version
if "%~1"=="setup" goto setup
if "%~1"=="check" goto check
goto invalid
:default
if "%DV_NO_PAUSE%"=="true" goto help
goto menu
:menu
if not "%~2"=="" goto invalid
call "%~dp0internal\windows\menu.bat"
set "DvExitCode=%errorlevel%"
goto return
:invalid
echo Invalid command. Use dev.bat help.
set "DvExitCode=2"
goto finish
:version
if not "%~2"=="" goto invalid
set "DvVersion="
set /p "DvVersion="<"%~dp0VERSION"
if not defined DvVersion goto versionFailed
echo dv %DvVersion%
goto finish
:setup
if "%~2"=="" goto setupMenu
call "%~dp0internal\windows\setup.bat" "%~2"
set "DvExitCode=%errorlevel%"
goto finish
:setupMenu
call "%~dp0internal\windows\menu.bat" setup
set "DvExitCode=%errorlevel%"
goto return
:check
if not "%~2"=="" goto invalid
call "%~dp0internal\windows\check.bat"
set "DvExitCode=%errorlevel%"
goto finish
:help
echo Usage: dev.bat [menu ^| setup [1^|2^|3^|4] ^| check ^| --version ^| help]
echo No argument: open the interactive menu. Press a number to select; Q to quit.
echo setup: open submenu. 1 enable WSL, 2 install Ubuntu, 3 configure WSL, 4 check.
echo check: inspect Windows and WSL. Run dev.sh inside Ubuntu for Linux tools.
goto finish

:versionFailed
set "DvExitCode=1"
goto finish
:finish
rem Keep results visible when launched by double-click or from a terminal.
rem Automation can set DV_NO_PAUSE=true to return immediately.
if "%DV_NO_PAUSE%"=="true" goto return
echo.
echo Finished. Press any key to return, or close this window.
pause >nul
:return
endlocal & exit /b %DvExitCode%
