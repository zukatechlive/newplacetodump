@echo off
setlocal

:: ─── Paths ───────────────────────────────────────────────────────────────────
set "SCRIPT_DIR=%~dp0"
set "INPUT=%SCRIPT_DIR%input.lua"
set "OUT_DIR=%SCRIPT_DIR%obfuscated"
set "OUTPUT=%OUT_DIR%\output.lua"

:: ─── Check input exists ───────────────────────────────────────────────────────
if not exist "%INPUT%" (
    echo [ERROR] input.lua not found in:
    echo         %SCRIPT_DIR%
    pause
    exit /b 1
)

:: ─── Create output folder if needed ──────────────────────────────────────────
if not exist "%OUT_DIR%" (
    mkdir "%OUT_DIR%"
    echo [INFO] Created folder: obfuscated\
)

:: ─── Run obfuscator ───────────────────────────────────────────────────────────
echo [INFO] Obfuscating input.lua ...
lua "%SCRIPT_DIR%bc.lua" "%INPUT%" "%OUTPUT%"

if %errorlevel% neq 0 (
    echo [ERROR] Obfuscation failed. Make sure lua.exe is in your PATH.
    pause
    exit /b 1
)

echo [DONE] Output written to: obfuscated\output.lua
pause
