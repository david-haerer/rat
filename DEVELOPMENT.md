# Development

## Zig

Rat is built with [Zig](https://ziglang.org/).
Follow the [Getting Started](https://ziglang.org/learn/getting-started/) guide for installation.

## Dependencies

Rat depends on the X11 libraries `xlib` and `xtst`.
Run the following command for installation on Debian.

```sh
sudo apt install libx11-dev libxtst-dev 
```

## Aliases

Useful development aliases are defined in [`.aliases`](./.aliases).
Run `source .aliases` to load these aliases in your shell. 

Alias | Command | Description
------|---------|------------
`build` | `sudo rm -rf zig-cache && zig build` | Build a development version of Rat.
`run` | `.zig-out/bin/rat` | Run the current build of Rat.
`release` | `sudo rm -rf zig-cache && zig build --release=safe` | Build a release version of Rat.
`develop` | `sudo watchexec -w src zig build` | Use [`watchexec`](https://github.com/watchexec/watchexec) to build Rat on every file change in [`src/`](./src/).
`logs` | `tail -f ~/.local/share/rat.log` | Monitor the log file.
