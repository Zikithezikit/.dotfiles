# Haimov's .dotfiles

To install the `.dotfiles`, clone the repo and then run the install script.

```bash
cd ~ && \
git clone https://github.com/Zikithezikit/.dotfiles ~/.dotfiles && \
cd ~/.dotfiles && \
bash ./install.sh
```

And that's it.

## Running i3 inside WSL

On a Windows machine with WSL, `i3` will not start on WSLg's display: WSLg
always has its own window manager (Weston) on it, so i3 exits with
`ERROR: Another window manager is already running`, and WSLg will not hand the
display over.

`wsl/` works around that by running a second, independent X server (Xvnc, from
TurboVNC) on a display of its own, where i3 is the only window manager. You
view it from Windows in a fullscreen VNC client.

```bash
i3-wsl-up    # checks deps, installs what is missing, starts the session
```

Then connect the VNC viewer to `localhost:5912` and press F11.

See `wsl/README.md` for the Windows side and the caveats.

