@echo off
rem NoiseOnEvent: write every .mp3 and .ogg file in this folder into Sounds.lua
setlocal
rem UTF-8 output for file names with special characters; old code page restored at the end
for /f "tokens=2 delims=:." %%C in ('chcp') do set "OLDCP=%%C"
chcp 65001 >nul
pushd "%~dp0"
set COUNT=0

rem new sound list, one line per file
> Sounds.lua (
    echo -- NoiseOnEvent sound list: every sound file in this folder, as offered in the dropdowns.
    echo -- Written by update-sounds.bat; run it again after adding or removing files.
    echo -- Then type /reload in game; new files need a game restart.
    echo.
    echo local _, ns = ...
    echo.
    echo -- file names in this folder
    echo ns.sounds = {
    for %%F in (*.mp3 *.ogg) do (
        echo   "%%F",
        set /a COUNT+=1 >nul
    )
    echo }
)

for %%F in (*.mp3 *.ogg) do echo [OK] %%F
echo [OK] %COUNT% sound files written to Sounds.lua
popd
chcp %OLDCP% >nul
pause
