@echo off
setlocal DisableDelayedExpansion
rem Shared argument validation only. Callers remain in setlocal scopes.
rem Neither configuration nor an inherited DvApply can authorize changes.
set "DvMode="
set "DvApply=false"
:parse
if "%~1"=="" goto done
if "%~1"=="--apply" goto apply
if "%~1"=="--dry-run" goto preview
echo Invalid mode. Use --apply or --dry-run, not both.
exit /b 2
:apply
if "%DvMode%"=="preview" goto conflict
if "%DV_DRY_RUN%"=="true" goto locked
set "DvMode=apply"
set "DvApply=true"
shift
goto parse
:preview
if "%DvMode%"=="apply" goto conflict
set "DvMode=preview"
shift
goto parse
:conflict
echo Do not combine --apply and --dry-run.
exit /b 2
:locked
echo DV_DRY_RUN=true prevents --apply.
exit /b 2
:done
if not "%~2"=="" exit /b 2
endlocal & set "DvApply=%DvApply%" & exit /b 0
