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
Rat starts in normal mode.

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
`h` / `LEFT` | Left
`y` | Left + 30° Up
`u` | Up + 30° Left
`k` / `UP` | Up
`i` | Up + 30° Right
`o` | Right + 30° Up
`l` / `RIGHT` | Right
`.` | Right + 30° Down
`,` | Down + 30° Right
`j` / `DOWN` | Down
`m` | Down + 30° Left
`n` | Left + 30° Down 

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

## Contributing

Thank you for considering to contribute! ❤️

### Feedback

If you run into problems or have feedback in general, feel free to open a [GitHub issue](https://github.com/david-haerer/rat/issues).

### Development

If you want to work on the code yourself, see [DEVELOPMENT.md](./DEVELOPMENT.md) for further documentation.

> [!TIP]
> For ideas on what to work on, have a look at the [GitHub issues](https://github.com/david-haerer/rat/issues)
> or the [Roadmap commit](https://github.com/david-haerer/rat/commit/dev).
