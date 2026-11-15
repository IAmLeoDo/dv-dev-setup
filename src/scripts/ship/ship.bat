@echo off
setlocal
for %%D in ("%~dp0..\..\..") do set "Root=%%~fD"
set "Source=%Root%\src\app"
set "Output=%Root%\dist"
fsutil reparsepoint query "%Output%" >nul 2>&1
if not errorlevel 1 (
    echo Refusing to replace a reparse point at dist/.
    exit /b 1
)
call :nextversion
if errorlevel 1 goto failed
set "Timestamp="
for /f "delims=" %%T in ('cscript //nologo "%~dp0ship-timestamp.js"') do set "Timestamp=%%T"
if not defined Timestamp goto failed
set "Output=%Root%\dist\v%NextVersion%_%Timestamp%"
if exist "%Output%" goto failed
mkdir "%Output%"
if errorlevel 1 goto failed
for /f "usebackq eol=# delims=" %%F in ("%~dp0ship-files.txt") do (
    call :copy "%%F"
    if errorlevel 1 goto failed
)
copy /b /y "%Root%\LICENSE" "%Output%\LICENSE" >nul
if errorlevel 1 goto failed
copy /b /y "%~dp0ship-readme.txt" "%Output%\README.txt" >nul
if errorlevel 1 goto failed
>"%Output%\VERSION" echo %NextVersion%
if errorlevel 1 goto failed
>"%Source%\VERSION" echo %NextVersion%
if errorlevel 1 goto failed
echo Version: %NextVersion%
echo Shipped %Output%
exit /b 0
:copy
set "Relative=%~1"
set "Relative=%Relative:/=\%"
for %%D in ("%Output%\%Relative%") do if not exist "%%~dpD" mkdir "%%~dpD"
if errorlevel 1 exit /b 1
copy /b /y "%Source%\%Relative%" "%Output%\%Relative%" >nul
exit /b %errorlevel%
:nextversion
rem Reject nonnumeric data before expanding it into any command.
if not exist "%Source%\VERSION" exit /b 1
findstr /r /c:"[^0-9.]" "%Source%\VERSION" >nul
if errorlevel 2 exit /b 1
if not errorlevel 1 exit /b 1
set "CurrentVersion="
for /f "usebackq delims=" %%V in ("%Source%\VERSION") do (
    call :readversion "%%V"
    if errorlevel 1 exit /b 1
)
if not defined CurrentVersion exit /b 1
rem Echo supplies CRLF so findstr /x also works when VERSION uses Linux LF.
echo %CurrentVersion%| findstr /r /x "[0-9][0-9]*\.[0-9]\.[0-9]" >nul
if errorlevel 1 exit /b 1
for /f "tokens=1-3 delims=." %%A in ("%CurrentVersion%") do (
    call :component "%%A"
    if errorlevel 1 exit /b 1
    call :component "%%B"
    if errorlevel 1 exit /b 1
    call :component "%%C"
    if errorlevel 1 exit /b 1
    set "Major=%%A"
    set "Minor=%%B"
    set "Patch=%%C"
)
set /a Patch+=1 >nul
if %Patch% LSS 10 goto versionReady
set "Patch=0"
set /a Minor+=1 >nul
if %Minor% LSS 10 goto versionReady
set "Minor=0"
if %Major% GEQ 999999 (
    echo Version limit reached ^(999999.9.9^).
    exit /b 1
)
set /a Major+=1 >nul
:versionReady
set "NextVersion=%Major%.%Minor%.%Patch%"
exit /b 0
:readversion
if defined CurrentVersion exit /b 1
set "CurrentVersion=%~1"
exit /b 0
:component
set "Part=%~1"
if not "%Part:~6%"=="" exit /b 1
if "%Part%"=="0" exit /b 0
if "%Part:~0,1%"=="0" exit /b 1
exit /b 0
:failed
echo Ship failed. Fix the reported error and run ship again before distributing the versioned bundle.
exit /b 1
