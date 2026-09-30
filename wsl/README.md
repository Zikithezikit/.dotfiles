# i3 on WSL

Running i3 inside WSL on a Windows work machine.

## The problem

WSLg gives you a full Linux GUI, but it is a *windowed* desktop, not a
nestable one. It puts its own window manager (Weston) on its display and will
not give it up, so:

```console
$ i3
ERROR: Another window manager is already running
```

This is not a misconfiguration. Microsoft has said there are no plans to
support custom window managers in WSLg
([wslg#516](https://github.com/microsoft/wslg/discussions/516),
[#67](https://github.com/microsoft/wslg/discussions/67),
[#81](https://github.com/microsoft/wslg/discussions/81)), and Weston cannot be
killed or replaced.

## The approach

Do not fight WSLg -- run a second X server. [TurboVNC]'s `Xvnc` gives us a
private X display (`:12`) with no window manager on it at all, so i3 is free to
be the one. You view that display from Windows with the TurboVNC Viewer.

This is the approach from [Per Weijnitz's write-up][article], with the
machine-specific parts pulled out into config and the pieces that do not apply
to WSL dropped.

[TurboVNC]: https://www.turbovnc.org/
[article]: https://perweij.gitlab.io/posts/i3-in-wsl/

## Install

```bash
bash ~/.dotfiles/wsl/install-wsl.sh
```

It needs sudo, and it installs:

| what | from |
| --- | --- |
| TurboVNC 3.3.1 | upstream `.deb` (not in apt) |
| `picom`, `feh`, `i3lock-fancy`, `xbacklight`, `pavucontrol`, `pulseaudio-utils`, `alsa-utils`, `xclip`, `fonts-font-awesome`, `dbus-x11` | apt |
| Iosevka + Symbols Nerd Fonts | `~/.local/share/fonts/NerdFonts`, no sudo |
| the `wsl` stow package | this repo |

It is safe to re-run; each step checks whether it is already done.

## Use

### From Windows

Double-click **`i3-wsl.bat` on your Desktop**. It starts the session, waits for
it, then opens the viewer already connected and in fullscreen. `install-wsl.sh`
puts it there; the source is `wsl/windows/i3-wsl.bat`.

Fullscreen is not cosmetic. i3 uses the Windows key as its modifier
(`$mod` = `Mod4` = Super), and Windows only hands that key to an application
that owns the whole screen. In a windowed viewer, Windows keeps the Super key
and every `Super`+key shortcut, so no i3 binding fires at all. The launcher
passes `-FullScreen`, which is a real TurboVNC Viewer parameter; inside a
session you can also toggle it with `Alt+Enter`.

### Windows steals some Super combinations

Even fullscreen, Windows reserves a set of `Super`+key shortcuts and consumes
them before the VNC viewer sees them. These are registered by the OS, so
nothing in i3, in this setup, or in the viewer can pass them through — they
lock the workstation or open Windows UI instead of reaching i3.

| combination | Windows does this | your i3 binding |
| --- | --- | --- |
| `Super`+L | **lock the workstation** | `$mod+l` focus right |
| `Super`+Shift+L | lock the workstation | `$mod+Shift+l` move right |
| `Super`+D | show desktop | `$mod+d` rofi launcher |
| `Super`+E | open File Explorer | `$mod+e` toggle split |
| `Super`+S | open Search | `$mod+s` stacking layout |
| `Super`+Space | switch input language | `$mod+space` rofi windows |
| `Super`+arrows | snap the window | `$mod+arrows` focus |
| `Super`+Shift+arrows | move window to other monitor | `$mod+Shift+arrows` move |
| `Super`+Shift+S | snip screenshot | `$mod+Shift+s` monitor script |

`Super`+L is the one that bites hardest, because `l` is a vim movement key and
the result is a locked workstation.

Two ways to deal with it, both on the **Windows** side, outside the VNC
session:

1. **Turn them off and on again as needed.** `Win-Hotkeys.bat` on your Desktop
   is a toggle: `Win-Hotkeys.bat off` while you are working in i3,
   `Win-Hotkeys.bat on` when you are not. It sets one per-user DWORD, so no
   administrator rights, and "on" deletes the value again so you return to the
   genuine Windows default rather than a remembered one. Your normal
   `Super`+E, `Super`+R, `Super`+D all keep working whenever you want them.

   ```bat
   reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoWinKeys /t REG_DWORD /d 1 /f
   ```

   > **This does not work on this machine.** That `Policies` branch is
   > ACL-locked: `reg add` there returns *Access is denied*, and the key cannot
   > even be queried, while ordinary `HKCU` keys write fine. That is an
   > intentional restriction — an organisation locking `Policies` so users
   > cannot apply policy to themselves, which is normal on a managed work PC.
   > `Win-Hotkeys.bat` detects this and says so rather than failing silently.
   > Ask IT if you want it changed, or use the Group Policy Editor equivalent
   > (*Turn off Windows Key hotkeys*), which needs administrator rights and may
   > be restricted too.

2. **Or move the colliding i3 bindings**, which needs no Windows change at
   all, is instant, and is trivially reversible. Windows claims a great many
   `Super`+letter combinations on a modern build — not just `L` but also `H`
   (voice typing), `A`, `C`, `F`, `G`, `I`, `K`, `M`, `Q`, `T`, `U`, `V`, `W`,
   `Y` — so a bare `Super` modifier is in tension with Windows generally.
   `Super`+`Alt`+letter, by contrast, is essentially unclaimed, which makes it
   the natural home for the affected bindings.

Running the launcher again is harmless — an already-running session is reused.

### From WSL

One command. It checks every dependency, installs whatever is missing, starts
the session, and tells you what to do on the Windows side:

```bash
i3-wsl-up
```

Run it as often as you like. Once everything is in place it does no work, asks
for no password, and just starts the session.

```
i3-wsl-up --check      report what is missing, change nothing
i3-wsl-up --no-start   set up, but leave the session stopped
```

The session survives the terminal that started it, so you can close the shell
and connect later.

Under the hood, `i3-wsl-up` checks the dependencies and then hands over to
`install-wsl.sh` (which needs sudo, and only when something is actually
missing) and `i3-wsl`, which manages the session itself:

```bash
i3-wsl start      # start Xvnc + i3
i3-wsl status     # is it up, and what to connect to
i3-wsl stop       # tear it down
i3-wsl restart
i3-wsl logs       # follow the session's output
i3-wsl env        # exports for pointing an already-open shell at the session
i3-wsl doctor     # check every dependency, and what is missing
```

The installer also **stages the Windows viewer for you**: it downloads the
official package and drops it in your Windows `Downloads` folder, so all you do
is double-click it. That sidesteps pasting URLs into `cmd.exe`, where quoting
and backslashes are a reliable source of trouble.

The wizard offers the TurboVNC **Server** as well as the **Viewer**. You only
need the Viewer — the X server runs inside WSL — so deselect the server and no
elevation prompt appears.

To skip the wizard:

```bat
TurboVNC-3.3.1-x64.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /CURRENTUSER
```

`/CURRENTUSER` (Inno Setup 6.1+, and this installer allows the override) makes
it a per-user install with no elevation.

This is an **Inno Setup** package, so the widely-copied NSIS flags `/S` and
`/D=` do nothing on it. That is the usual reason silent-install attempts here
fail.

### Connect

Connect to `localhost:5912` (`DISPLAY_NUM=12` in the config, plus 5900).

### Go fullscreen

Switch the viewer to fullscreen (F11) before you start working. In windowed
mode Windows intercepts the Super key, so `$mod+Return`, `$mod+d` and every
other i3 binding are dead. Fullscreen hands them to i3.

## Configuration

`~/.config/i3-wsl/config` (stowed from `wsl/.config/i3-wsl/config`):

| setting | default | notes |
| --- | --- | --- |
| `DISPLAY_NUM` | `12` | → RFB port `5912` |
| `GEOMETRY` | `1920x1200` | match your monitor, or the viewer scales and the mouse skews |
| `DEPTH` | `24` | drop to `16` to halve VNC bandwidth, at the cost of colour banding |
| `LAYOUT` | `us,il` | applied before i3 starts |
| `RFBAUTH` | *(empty)* | path to a `vncpasswd` file; empty = no password |
| `XVNC_EXTRA` | *(empty)* | extra flags for the vncserver command line |

Find your monitor's real resolution with:

```powershell
Get-CimInstance Win32_VideoController |
  select CurrentHorizontalResolution, CurrentVerticalResolution
```

## What this setup changes about your i3 config

`i3/.config/i3/config` used to assume a two-monitor Linux desktop. Under VNC
there is one virtual screen with no `DP-1` or `DVI-D-0`, so those directives
are now in `~/.config/i3.local.conf`, included only if it exists. See
`i3/.config/i3/i3.local.conf.example` -- copy it to `~/.config/i3.local.conf`
on a real multi-monitor machine, and leave it absent on WSL.

Four other fixes apply to both machines:

- `grp:win_space_toggle` could never fire, because `$mod+space` is bound to
  rofi and i3 grabs the key first. Now `grp:alt_space_toggle`, which is also
  `$mod`+`Space` to i3, so it needs no modifier of its own.
- `nm-applet`, `kdeconnectd` and `kdeconnect-indicator` are started only if
  installed. WSL has no NetworkManager or Bluetooth; a minimal desktop may
  lack kdeconnect.
- The wallpaper loop is guarded on its glob matching, so an empty
  `~/Pictures/Wallpapers` no longer spins `feh` forever.
- `picom` is now started with `--backend xrender`. picom 12.x refuses to start
  without an explicit backend (`Backend not specified`), so this was failing on
  a real desktop too, not just here.
- `gammastep` is only started if it is installed, since it cannot work under
  WSL (no gamma-ramp interface) and the bare exec logged `not found` on every
  reload.

## "A window doesn't fit in i3"

Two separate causes, both of which look like an i3 bug and are not.

### The desktop is the wrong size (the usual one)

TurboVNC lets the client resize the X screen to match itself. When the client
is bigger than the geometry you configured, the screen grows but the *output*
keeps the position it was given, instead of growing with it:

```
Screen 0: current 3840 x 1200
VNC-0 connected 1920x1200+1920+0 0mm x 0mm
```

A 3840-wide screen with a 1920-wide output sitting at `x=1920` means i3 tiles
every window at `x=1930` — entirely off the right edge of what you can see.
The desktop looks half-empty and nothing appears to fit, and no amount of
resizing or reloading in i3 will help because nothing is wrong with i3.

`i3-wsl doctor` and `i3-wsl start` both check for this and say so, with the
fix. To fix it properly, pin the size (needs sudo once):

```bash
bash ~/.dotfiles/wsl/install-wsl.sh    # enables no-remote-resize
```

or accept the size the client wants and stop fighting it — set
`GEOMETRY=3840x1200` in `~/.config/i3-wsl/config` and restart the session.
That is the right answer if you want the desktop to span both monitors.

### The app is GTK4 and drew itself a subsurface

On a machine with no DRI3/EGL device — which is the case for a
software-rasterised Xvnc — GTK4 renders through a *subsurface*: it creates a
hidden 1x1 override-redirect toplevel and puts the real window underneath it
as a child. A window manager only ever sees root children, so i3 cannot manage
that window at all: it keeps the size and position GTK chose and ignores
tiling, moving and focus.

`wsl/.config/i3-wsl/xsession` fixes it for every app in the session:

```
export GDK_BACKEND=x11      # GTK4 otherwise may not fall back to X11 at all
export GSK_RENDERER=cairo   # gives GTK an ordinary managed toplevel
```

## WSLg is left enabled, and what that costs

WSLg is not what blocks i3 -- i3 simply runs on a different display -- so
there is no reason to give up the WSLg apps. It is not entirely free, though,
and this is the concrete reason:

**WSLg mounts `/tmp/.X11-unix` as its own read-only tmpfs**, so a second X
server has nowhere to put its display socket:

```
$ grep X11 /proc/mounts
none /tmp/.X11-unix tmpfs ro,relatime 0 0
```

Xvnc then logs `failed to bind listener` and every client fails with
`Cannot open display ":12"`. So `i3-wsl` picks a transport at startup and tells
you which it used:

| transport | when | how |
| --- | --- | --- |
| Unix socket | `/tmp/.X11-unix` is writable | `DISPLAY=:12`, the normal case |
| TCP on loopback | WSLg has made it read-only | `DISPLAY=127.0.0.1:12` |

The TCP path needs `-listen tcp`, because TurboVNC disables X11 TCP by
default (`/etc/turbovncserver-security.conf`: *"X11 TCP connections are
disabled but can be enabled by passing `-listen tcp`"*). No Xauthority changes
are needed: Xvnc writes one cookie for the session into `~/.Xauthority` and
accepts it for loopback connections whatever address they arrive from.

One thing to be aware of on the TCP path: Xvnc binds the X11 port
(`6012`) to `0.0.0.0`, and `-localhost` does not restrict it -- the X server
has no per-address bind option. The cookie is still required (a client with an
empty `XAUTHORITY` is refused), and WSL2's NAT means the VM address is not
routable from your LAN, so it is not casually usable. But it is a wider door
than it needs to be.

To close it, turn WSLg off. In `%USERPROFILE%\.wslconfig`:

```ini
[wsl2]
guiApplications=false
```

then `wsl --shutdown` **from PowerShell** (it cannot be run from inside the
session it is shutting down). Afterwards `/tmp/.X11-unix` is an ordinary
writable directory, `i3-wsl` switches to the Unix socket on its own, and there
is no X11 TCP listener at all. You lose native Windows GUI windows and save
roughly 200 MB of RAM.

## Caveats

- **Software rendering.** The VNC display is a software-rasterised Xvnc with no
  GPU acceleration. Terminals, editors and rofi are fine; a browser playing
  video is not. For heavy GUI work, use WSLg's native windows instead.
- **A second desktop.** WSLg and the VNC session are independent. An app you
  launch from a normal WSL shell opens as a WSLg window outside i3. To put it
  *in* i3, start it from a terminal inside the session, or use `i3-wsl env`.
- **Wayland apps.** `xsession` unsets `WAYLAND_DISPLAY` on purpose. Left set,
  GTK4/libadwaita apps connect to WSLg's Weston and pop up outside i3.
- **Audio.** WSLg already exports `PULSE_SERVER`, so `pactl` and polybar's
  volume module work once `pulseaudio-utils` is installed.
- **Security.** The server is always started with `-localhost`, so it only
  accepts connections relayed from Windows itself, and no password is required
  by default. Add one with `RFBAUTH` if the machine is on a shared or
  untrusted network. Note that a local VNC server can read anything you type
  into it; on a locked-down work machine, check your IT policy before running
  one.
