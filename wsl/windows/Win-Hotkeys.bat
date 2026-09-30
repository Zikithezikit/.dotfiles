@echo off
REM ===========================================================================
REM  Windows key shortcuts: on / off / toggle
REM
REM  ---- READ THIS FIRST: it does not solve Super+L ----------------------------
REM
REM  This switches off the Windows *shell* hotkeys -- Super+D, Super+E,
REM  Super+S, Super+arrows and friends -- so they reach i3 instead.
REM
REM  It does NOT disable Super+L. Locking the workstation is a core function
REM  handled outside the shell hotkey dispatcher that this policy governs, so
REM  no value of NoWinKeys stops it. On a managed machine the Policies branch
REM  may also be ACL-locked, in which case this script cannot write at all --
REM  it detects that and says so rather than pretending.
REM
REM  Nothing in i3, in this setup, or in the VNC viewer can pass Super+L
REM  through, because Windows consumes it first. The only fix is to not ask
REM  for Super+L: bind i3's "focus right" / "move right" to something Windows
REM  does not claim. See wsl/README.md.
REM
REM  Why this exists at all: i3 uses the Windows key as its modifier, and
REM  Windows claims a set of Super+key combinations for itself before the VNC
REM  viewer ever sees them.
REM
REM  You do not have to live without them permanently. Turn them off while
REM  you are working in the i3 session, and back on when you are not:
REM
REM      Win-Hotkeys.bat            toggle, and report what actually happened
REM      Win-Hotkeys.bat off        disable the shell hotkeys (for i3)
REM      Win-Hotkeys.bat on         restore the Windows defaults
REM      Win-Hotkeys.bat --help
REM
REM  It sets one per-user DWORD, so it affects only this Windows account. "on"
REM  deletes the value again rather than writing a 0, so you go back to the
REM  real Windows default instead of a remembered one.
REM
REM  Administrator rights are needed. If an organisation has locked the
REM  per-user Policies branch, a normal token gets "Access is denied" there;
REM  elevating may get past it. Rather than fail, this script re-launches
REM  itself with a UAC prompt when it needs to write and is not already
REM  elevated. If your account is not an administrator at all, run it from an
REM  elevated PowerShell instead:
REM
REM      PS> .\Win-Hotkeys.bat off
REM
REM  Note that HKCU is per user, so keep elevating *your own* account. Running
REM  it as a different administrator would change that account's shortcuts and
REM  not yours.
REM ===========================================================================

setlocal EnableDelayedExpansion

set "KEY=HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
set "VAL=NoWinKeys"
set "SELF=%~f0"

set "ACTION=%~1"
if /i "%ACTION%"=="-h"       goto :usage
if /i "%ACTION%"=="--help"  goto :usage
if /i "%ACTION%"=="/?"       goto :usage
if not defined ACTION       set "ACTION=toggle"
if /i not "%ACTION%"=="on"    if /i not "%ACTION%"=="off"    if /i not "%ACTION%"=="toggle"    goto :usage

REM --- read the current value ---------------------------------------------
call :readState
set "CUR=%STATE%"          REM 0x1 = hotkeys off, 0x0 = on, EMPTY = default(on)

if /i "%CUR%"=="0x1" (set "IS_OFF=1") else (set "IS_OFF=0")

set "WANT_OFF=%IS_OFF%"
if /i "%ACTION%"=="off"    set "WANT_OFF=1"
if /i "%ACTION%"=="on"     set "WANT_OFF=0"
if /i "%ACTION%"=="toggle" set /a WANT_OFF=1-IS_OFF

REM What is on screen right now, as a comparable token.
if "%CUR%"=="0x1" (set "CUR_TXT=off") else (set "CUR_TXT=on")

REM --- nothing to do? -----------------------------------------------------
if "%WANT_OFF%"=="%IS_OFF%" (
    call :report "%CUR_TXT%" 0
    exit /b 0
)

REM --- needs to write, so make sure we can -------------------------------
REM fltmc is a quiet, reliable administrator check.
fltmc >nul 2>&1
if errorlevel 1 (
    echo.
    echo   Changing this needs administrator rights -- requesting them now...
    echo.
    powershell -NoProfile -Command ^
        "Start-Process -FilePath '%SELF%' -ArgumentList '%ACTION%' -Verb RunAs" >nul 2>&1
    if errorlevel 1 (
        echo   x  Could not request elevation. Run this from an
        echo      administrator PowerShell instead:
        echo.
        echo        PS^> %SELF% %ACTION%
        echo.
        pause
        exit /b 1
    )
    echo   A new window will open with a UAC prompt. This one is done.
    timeout /t 3 /nobreak >nul
    exit /b 0
)

REM --- apply --------------------------------------------------------------
if "%WANT_OFF%"=="1" (
    reg add "%KEY%" /v %VAL% /t REG_DWORD /d 1 /f >nul 2>&1
) else (
    REM Deleting is "back to the Windows default". Failing here just means
    REM there was nothing to delete, which is the state we wanted anyway.
    reg delete "%KEY%" /v %VAL% /f >nul 2>&1
)

REM --- verify, do not assume ---------------------------------------------
call :readState
if "%WANT_OFF%"=="1" (
    if /i "%STATE%"=="0x1" (call :report off 0) else (call :report off 1)
) else (
    if /i "%STATE%"=="0x1" (call :report on 1) else (call :report on 0)
)
exit /b %ERRORLEVEL%

REM ===========================================================================
:readState
set "STATE="
for /f "tokens=3" %%a in ('reg query "%KEY%" /v %VAL% 2^>nul ^| findstr /I "%VAL%"') do set "STATE=%%a"
if not defined STATE set "STATE=0x0"
exit /b 0

REM ---------------------------------------------------------------------------
:report
REM  %1 = on|off (the state now), %2 = 0 ok / 1 failed
echo.
if "%~2"=="0" (
    if /i "%~1"=="off" (
        echo   Windows key shortcuts: OFF
        echo.
        echo     Super, and Super+letters, now pass through to applications
        echo     -- so in a fullscreen TurboVNC Viewer they reach i3, and
        echo     Super+L no longer locks the machine.
        echo.
        echo     On the Windows desktop, Super+E, Super+R, Super+D and the
        echo     rest will not work while this is off.
        echo.
        echo     To get them back:  %~nx0 on
    ) else (
        echo   Windows key shortcuts: ON ^(Windows defaults^)
        echo.
        echo     Super+E, Super+R, Super+D and the rest work again.
        echo.
        echo     In a fullscreen VNC session, Super+L will lock the
        echo     workstation again, and the other Super combinations Windows
        echo     claims go to Windows rather than to i3.
        echo.
        echo     To hand the key over to i3 again:  %~nx0 off
    )
    echo.
    echo   If a change does not seem to take effect straight away, sign out
    echo   and back in -- Windows reads this policy when the shell starts.
    echo.
    pause
    exit /b 0
)

echo   x  The change did not stick -- the value is still not what was asked
echo      for. That means something else is writing this key, most likely
echo      Group Policy from your IT department, which will win on its own
echo      schedule.
echo.
echo     Ask IT, or leave it: the alternative that needs no Windows change
echo     is to move the colliding i3 bindings onto keys Windows does not
echo     claim. See wsl/README.md.
echo.
pause
exit /b 1

REM ---------------------------------------------------------------------------
:usage
echo.
echo   %~nx0 [on^|off^|toggle]
echo.
echo     on       restore the Windows defaults ^(Super+E, Super+R, ...^)
echo     off      let Super reach i3: no Super+L lock, no Windows stealing
echo               Super+letters
echo     toggle   flip between the two ^(default^)
echo.
echo   Needs administrator rights, and asks for them if it does not have them.
echo   Affects only this Windows account.
echo.
pause
exit /b 1
