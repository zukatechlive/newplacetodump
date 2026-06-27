@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "INPUT=%SCRIPT_DIR%input.lua"
set "ZUK=%SCRIPT_DIR%zuk.lua"
set "OUTDIR=%SCRIPT_DIR%scripts"

echo [ZukaTech] Checking files...

if not exist "%INPUT%" (
    echo [ERROR] input.lua not found in %SCRIPT_DIR%
    pause
    exit /b 1
)

if not exist "%ZUK%" (
    echo [ERROR] zuk.lua not found in %SCRIPT_DIR%
    pause
    exit /b 1
)

if not exist "%OUTDIR%" (
    echo [ERROR] scripts folder not found in %SCRIPT_DIR%
    pause
    exit /b 1
)

echo.
echo Select a preset:
echo   [1] Default
echo   [2] Standard
echo   [3] Double
echo   [4] Basic
echo.

set /p "PRESET_CHOICE=Enter 1, 2, 3, or 4: "

if "%PRESET_CHOICE%"=="1" (
    set "PRESET=Default"
) else if "%PRESET_CHOICE%"=="2" (
    set "PRESET=Standard"
)else if "%PRESET_CHOICE%"=="3" (
    set "PRESET=Double"
)else if "%PRESET_CHOICE%"=="4" (
    set "PRESET=Basic"
) else (
    echo [ERROR] Invalid choice. Enter 1 or 2.
    pause
    exit /b 1
)

echo.
set /p "OUTNAME=Enter output file name (without .lua): "
if "%OUTNAME%"=="" (
    echo [ERROR] No name entered.
    pause
    exit /b 1
)

set "OUTPUT=%OUTDIR%\%OUTNAME%.lua"

echo.
echo [ZukaTech] Running with preset: %PRESET%
echo [ZukaTech] Output: scripts\%OUTNAME%.lua
echo.

lua "%ZUK%" "%INPUT%" %PRESET% "%OUTPUT%"

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] ZukaTech failed with error code %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)

if not exist "%OUTPUT%" (
    echo [ERROR] Output was not produced.
    pause
    exit /b 1
)

echo.
echo [ZukaTech] Done! Saved to scripts\%OUTNAME%.lua
pause
