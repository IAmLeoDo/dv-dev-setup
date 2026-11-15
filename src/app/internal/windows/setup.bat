@echo off
setlocal
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
call "%~dp0enable-wsl.bat"
exit /b %errorlevel%
:ubuntu
call "%~dp0install-ubuntu.bat"
exit /b %errorlevel%
:config
call "%~dp0configure-wsl.bat"
exit /b %errorlevel%
:check
call "%~dp0check.bat"
exit /b %errorlevel%
:invalid
echo Invalid step. Use dev.bat help.
exit /b 2
:help
echo Usage: dev.bat setup [1^|2^|3^|4^|--help]
echo No argument: interactive submenu; B returns. 1: features, 2: Ubuntu, 3: config, 4: check.
echo Enable features as administrator; install Ubuntu under your development account.
exit /b 0
