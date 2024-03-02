<p align="center">
  <h1 align="center">Rat 🐀</h1>
</p>

<p align="center">
  <em>keyboard. driven. mouse.</em>
</p>

## Installation

> [!IMPORTANT]
> Rat only works on Linux with X11 and only with a single display.

Download the pre-built binary from the [GitHub Releases page](https://github.com/david-haerer/rat/releases) and add it to your `$PATH`.

> [!TIP]
> For easy access define a keyboard shortcut to launch Rat.

## Keybindings

Rat grabs the keyboard during execution, such that only the following keys are active.

### Modes

The following keys change the mode Rat is working in.

Key | Mode
----|---------
`q` | Exit Rat.
`s` | Scroll mode.
`ESCAPE` | Return to normal mode.

### Directions

The following keys set the direction.
The action taken depends on the current mode.

* In normal mode, the pointer is moved.
* In scroll mode, the page is scrolled.

Key | Direction
----|---------
`LEFT` / `h` | Left
`DOWN` / `j` | Down
`UP` / `k` | Up
`RIGHT` / `l` | Right

### Buttons

The following keys act as the three mouse buttons.

Key | Button
----|---------
`SPACE` | Left
`x` | Middle
`r` | Right

## Alternatives

> [!NOTE]
> Since Rat is still in early development, here's a list of more mature alternatives.
> If you know of a program that would fit this list, feel free to reach out ❤️

Name | Platform | Description
----|----|-------
[warpd](https://github.com/rvaiya/warpd) | `X11` `Wayland` `macOS` | A modal keyboard driven interface for mouse manipulation.
[keynav](https://github.com/jordansissel/keynav) | `X11` | Control the mouse with the keyboard.
[keynavish](https://github.com/lesderid/keynavish) | `Windows` | Control the mouse with the keyboard, on Windows.
[TPMouse](https://github.com/EsportToys/TPMouse) | `Windows` | A virtual trackball for Windows, via vim-like homerow controls. 
[AhkCoordGrid](https://github.com/GavinPen/AhkCoordGrid) | `Windows` | AutoHotkey code for Windows overlay grid allowing you to emulate mouse click at different points on the screen using keyboard shortcuts.
[Mouseable](https://github.com/wirekang/mouseable) | `Windows` | Control the mouse via the keyboard.
[win-vind](https://github.com/pit-ray/win-vind) | `Windows` | You can operate Windows with key bindings like Vim.
[Scoot](https://github.com/mjrusso/scoot) | `macOS` | Your friendly cursor teleportation and actuation tool.
[Shortcat](https://shortcat.app/) | `macOS` | Manipulate macOS masterfully, minus the mouse.
[vimac](https://vimacapp.com/) | `macOS` | Stop using your clunky trackpad/mouse now.
[Homerow](https://www.homerow.app/) | `macOS` | Keyboard shortcuts for every button in macOS.
[Superkey](https://superkey.app/) | `macOS` | Simple and powerful keyboard enhancement on macOS.


## Troubleshooting

### Dependencies

Make sure the *X11 Testing -- Record extension library* is installed.

```sh
sudo apt install libxtst6 
```

### Logs

The log outputs of Rat can be found in `$HOME/.local/share/rat.log`.

## Development

### Zig

Rat is built with [Zig](https://ziglang.org/).
Follow the [Getting Started](https://ziglang.org/learn/getting-started/) guide for installation.

### Dependencies

Rat depends on the X11 libraries `xlib` and `xtst`.
Run the following command for installation on Debian.

```sh
sudo apt install libx11-dev libxtst-dev 
```

### Build

To build the executable, run the following command:

```sh
zig build
```

You can use [`watchexec`](https://github.com/watchexec/watchexec) to build on every file change:

```sh
sudo watchexec -w src/ zig build
```

### Run

Launch Rat with

```sh
./zig-out/bin/rat
```
