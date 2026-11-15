@echo off
setlocal
set "DvMenuResult=0"
if "%DV_NO_PAUSE%"=="true" goto noninteractive
if "%~1"=="setup" goto openSetup
if not "%~1"=="" exit /b 2
call :appearance
goto home
:openSetup
call :appearance
goto setupMenu
:home
call :header
echo   MAIN MENU
echo.
echo     [1]  Set up Windows / WSL2
echo          Features, Ubuntu installation and resource settings
echo     [2]  Check environment
echo          Inspect Windows and WSL readiness
echo     [3]  Show version
echo     [4]  Help and command reference
echo.
echo     [Q]  Quit
echo.
choice /c 1234Q /n /m "  Select [1-4, Q]: "
if errorlevel 255 goto inputFailed
if errorlevel 5 goto done
if errorlevel 4 goto help
if errorlevel 3 goto version
if errorlevel 2 goto check
if errorlevel 1 goto setupFromHome
goto inputFailed
:setupFromHome
call "%~f0" setup
set "DvMenuResult=%errorlevel%"
goto home
:check
call :header
echo   CHECK ENVIRONMENT
echo.
call "%~dp0check.bat"
set "DvMenuResult=%errorlevel%"
call :result
goto home
:version
call :header
echo   VERSION
echo.
set "DV_NO_PAUSE=true"
call "%~dp0..\..\dev.bat" --version
set "DvMenuResult=%errorlevel%"
set "DV_NO_PAUSE="
call :result
goto home
:help
call :header
echo   COMMAND REFERENCE
echo.
set "DV_NO_PAUSE=true"
call "%~dp0..\..\dev.bat" help
set "DvMenuResult=%errorlevel%"
set "DV_NO_PAUSE="
echo.
echo   Run Windows setup step 1 as administrator.
echo   Run steps 2 and 3 as your normal development account.
echo   Run dev.sh inside Ubuntu for Linux tools and Bash aliases.
call :result
goto home
:setupMenu
call :header
echo   SET UP WINDOWS / WSL2
echo.
echo     [1]  Enable WSL2 features           Administrator required
echo     [2]  Install Ubuntu 24.04          Development account
echo     [3]  Configure memory and swap     Development account
echo     [4]  Check environment             Read-only diagnostics
echo.
echo     [B]  Back / close setup menu
echo.
echo   Run one step at a time. Save work before any manual restart.
echo.
choice /c 1234B /n /m "  Select [1-4, B]: "
if errorlevel 255 goto inputFailed
if errorlevel 5 goto done
if errorlevel 4 goto step4
if errorlevel 3 goto step3
if errorlevel 2 goto step2
if errorlevel 1 goto step1
goto inputFailed
:step1
set "DvStep=1"
goto runStep
:step2
set "DvStep=2"
goto runStep
:step3
set "DvStep=3"
goto runStep
:step4
set "DvStep=4"
:runStep
call :header
echo   WINDOWS SETUP / STEP %DvStep%
echo.
call "%~dp0setup.bat" "%DvStep%"
set "DvMenuResult=%errorlevel%"
call :result
goto setupMenu
:appearance
set "DvRed="
set "DvGreen="
set "DvReset="
set "DvHeaderVersion=unknown"
if exist "%~dp0..\..\VERSION" set /p "DvHeaderVersion="<"%~dp0..\..\VERSION"
rem Native ANSI colors for modern Windows terminals; no terminal settings change.
if defined NO_COLOR exit /b 0
if "%TERM%"=="dumb" exit /b 0
for /f %%E in ('echo prompt $E ^| cmd.exe /d /q') do set "DvEscape=%%E"
if not defined DvEscape exit /b 0
set "DvRed=%DvEscape%[31m"
set "DvGreen=%DvEscape%[32m"
set "DvReset=%DvEscape%[0m"
exit /b 0
:header
cls
echo.
echo %DvRed%   ____ __     __   ____ _     ___ %DvReset%
echo %DvRed%  ^|  _ \ \   / /  / ___^| ^|   ^|_ _^|%DvReset%
echo %DvRed%  ^| ^| ^| \ \ / /  ^| ^|   ^| ^|    ^| ^| %DvReset%
echo %DvRed%  ^| ^|_^| ^|\ V /   ^| ^|___^| ^|___ ^| ^| %DvReset%
echo %DvRed%  ^|____/  \_/     \____^|_____^|___^|%DvReset%
echo.
echo %DvGreen%  DV CLI: %DvHeaderVersion%%DvReset%
echo %DvGreen%  OS: Windows%DvReset%
echo %DvGreen%  Target: Ubuntu 24.04 / WSL2%DvReset%
echo.
exit /b 0
:result
echo.
if "%DvMenuResult%"=="0" goto succeeded
if "%DvMenuResult%"=="3010" goto restartRequired
echo   [FAILED] Command returned exit code %DvMenuResult%.
echo   Review the details above before trying again.
goto wait
:restartRequired
echo   [RESTART REQUIRED] Save your work and restart Windows manually.
goto wait
:succeeded
echo   [OK] Command completed.
:wait
echo.
echo   Press any key to return to the menu.
pause >nul
exit /b 0
:noninteractive
echo Interactive menus are disabled by DV_NO_PAUSE=true.
echo Use dev.bat setup 1, setup 2, setup 3, check, --version or help.
exit /b 2
:inputFailed
echo Unable to read a menu selection. Run from an interactive terminal.
set "DvMenuResult=1"
:done
endlocal & exit /b %DvMenuResult%
