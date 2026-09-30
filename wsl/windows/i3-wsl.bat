@echo off
REM ===========================================================================
REM  i3 on WSL -- one click.
REM
REM  Starts the i3 session inside WSL (installing anything missing on the
REM  way), waits for it to be ready, then opens the TurboVNC Viewer already
REM  connected and in fullscreen.
REM
REM  Fullscreen is not cosmetic. i3 uses the Windows key as its modifier
REM  ($mod = Mod4 = Super), and Windows only lets that key through to an
REM  application that owns the whole screen. In a windowed viewer, Windows
REM  keeps Super itself and every Super+key shortcut, so no i3 binding fires.
REM
REM  Even in fullscreen, Windows keeps a few of its own and consumes them
REM  before this viewer ever sees them. Nothing here can change that:
REM
REM    Super+L / Super+Shift+L   lock the workstation  (vs $mod+l  focus right)
REM    Super+D                   show desktop           (vs $mod+d  rofi)
REM    Super+E                   open File Explorer     (vs $mod+e  toggle split)
REM    Super+S                   open Search            (vs $mod+s  stacking)
REM    Super+Space               switch input language  (vs $mod+space rofi)
REM    Super+arrows              snap the window        (vs $mod+arrows focus)
REM    Super+Shift+S             screenshot             (vs $mod+Shift+s monitor)
REM
REM  Super+L is the nasty one, since l is a vim movement key and the result is
REM  a locked workstation. To stop it, on the Windows desktop (not in here):
REM
REM    Settings > Keyboard > Keyboard shortcuts > Hotkeys
REM      and clear "Lock the computer - Super+L", or disable them all with
REM
REM      reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" ^
REM          /v NoWinKeys /t REG_DWORD /d 1 /f
REM
REM  Both are reversible, but both also change Super behaviour outside this
REM  session. See wsl/README.md for the full list and the caveats.
REM
REM  Running it again is harmless: an already-running session is reused.
REM ===========================================================================

setlocal enabledelayedexpansion
title i3 on WSL

REM ---- configuration -------------------------------------------------------
REM Leave DISTRO empty to use the default WSL distribution.
set "DISTRO=Ubuntu"
set "VNC_HOST=localhost"
set "VNC_PORT=5912"
set "WAIT_SECONDS=45"

REM -d is only passed when DISTRO is set; wsl.exe wants nothing between the
REM distro and "--" otherwise.
if defined DISTRO (set "DISTRO_ARG=-d %DISTRO%") else (set "DISTRO_ARG=")

echo.
echo   Starting i3 in WSL...
echo.

REM ---- 1. Find the TurboVNC Viewer ----------------------------------------
set "VIEWER="
for %%P in (
    "%ProgramFiles%\TurboVNC\vncviewer.bat"
    "%ProgramFiles(x86)%\TurboVNC\vncviewer.bat"
    "%LOCALAPPDATA%\TurboVNC\vncviewer.bat"
    "%LOCALAPPDATA%\Programs\TurboVNC\vncviewer.bat"
    "%LOCALAPPDATA%\Programs\TurboVNC Viewer\vncviewer.bat"
) do (
    if exist %%P if not defined VIEWER set "VIEWER=%%~P"
)

if not defined VIEWER (
    echo   x  Could not find the TurboVNC Viewer.
    echo.
    echo     Install it first: run TurboVNC-3.3.1-x64.exe from your
    echo     Downloads folder. install-wsl.sh puts it there for you.
    echo.
    pause
    exit /b 1
)

REM ---- 2. Start the session in WSL -----------------------------------------
REM Resolve the Linux user rather than hardcoding it, so this keeps working
REM if the WSL account is renamed. "wsl -- id -un" needs no quoting, which
REM matters: nested quotes through wsl.exe from batch are a trap.
set "LUSER="
for /f "usebackq delims=" %%u in (`wsl.exe !DISTRO_ARG! -- id -un 2^>nul`) do set "LUSER=%%u"

if not defined LUSER (
    echo   x  Could not talk to WSL. Is the distribution called "!DISTRO!"?
    echo     Edit DISTRO at the top of this file if it has a different name.
    echo.
    pause
    exit /b 1
)

REM i3-wsl-up checks every dependency, installs what is missing, and starts
REM the session. If something IS missing it needs your sudo password, and it
REM prompts on this console -- so type it here if asked.
wsl.exe !DISTRO_ARG! -- "/home/!LUSER!/.local/bin/i3-wsl-up"
if errorlevel 1 (
    echo.
    echo   x  i3-wsl-up failed. Scroll up for the reason.
    echo.
    pause
    exit /b 1
)

REM ---- 3. Wait for the X server to accept connections ----------------------
echo.
echo   Waiting for the session to come up...

set /a TRIES=0
:WAIT_FOR_PORT
set /a TRIES+=1
netstat -ano | findstr /R /C:":!VNC_PORT! .*LISTENING" >nul && goto READY
if !TRIES! GEQ !WAIT_SECONDS! (
    echo.
    echo   x  Timed out after !WAIT_SECONDS!s waiting for port !VNC_PORT!.
    echo.
    echo     The session log will say why:
    echo       wsl.exe !DISTRO_ARG! -- tail -n 40 /home/!LUSER!/.local/state/i3-wsl/vnc.log
    echo.
    pause
    exit /b 1
)
timeout /t 1 /nobreak >nul
goto WAIT_FOR_PORT

:READY
echo   Session is up on port !VNC_PORT!.

REM ---- 4. Connect, fullscreen ---------------------------------------------
REM -FullScreen is a real TurboVNC Viewer parameter. The same effect is
REM available in-session with Alt+Enter, but doing it here means the window
REM is already fullscreen by the time you can press an i3 key.
echo   Opening the viewer (fullscreen)...
start "" /min "%VIEWER%" -FullScreen !VNC_HOST!:!VNC_PORT!

echo.
echo   Done. The i3 desktop should be on screen.
echo   Super+Return opens a terminal, Super+d the launcher, Super+Shift+q
echo   closes a window. Press F11 to leave fullscreen.
echo.
echo   This window will close on its own.
timeout /t 4 /nobreak >nul
exit /b 0
