@echo off
setlocal DisableDelayedExpansion
if not "%~4"=="" goto invalid
if "%~1"=="--help" goto help
if "%~1"=="help" goto help
if "%~1"=="1" goto features
if "%~1"=="2" goto ubuntu
if "%~1"=="3" goto config
if "%~1"=="4" goto check
if not "%~1"=="" goto invalid
call "%~dp0menu.bat" setup
exit /b %errorlevel%
:features
call "%~dp0enable-wsl.bat" "%~2" "%~3"
exit /b %errorlevel%
:ubuntu
call "%~dp0install-ubuntu.bat" "%~2" "%~3"
exit /b %errorlevel%
:config
call "%~dp0configure-wsl.bat" "%~2" "%~3"
exit /b %errorlevel%
:check
if not "%~2"=="" goto invalid
call "%~dp0check.bat"
exit /b %errorlevel%
:invalid
echo Invalid step. Use dev.bat help.
exit /b 2
:help
echo Usage: dev.bat setup [1^|2^|3] [--apply ^| --dry-run]
echo        dev.bat setup 4
echo Default: summary only. Add --apply to make changes. Step 4 is read-only.
echo No argument: interactive submenu; B returns. 1: features, 2: Ubuntu, 3: config, 4: check.
echo Enable features as administrator; install Ubuntu under your development account.
exit /b 0
