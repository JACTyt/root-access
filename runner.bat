@echo off
rem Quick launcher for Root Access.
rem   runner.bat          run the game
rem   runner.bat editor   open the project in the Godot editor
rem Set GODOT to your Godot 4.7+ executable to override the default path.

setlocal
if not defined GODOT set "GODOT=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64.exe"

if not exist "%GODOT%" (
    echo Godot not found at "%GODOT%".
    echo Set the GODOT environment variable to your Godot 4.7+ executable.
    exit /b 1
)

if /i "%~1"=="editor" (
    start "" "%GODOT%" --path "%~dp0." --editor
) else (
    start "" "%GODOT%" --path "%~dp0."
)
endlocal
