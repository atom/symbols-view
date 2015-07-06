# Symbols View package [![Build Status](https://travis-ci.org/atom/symbols-view.svg?branch=master)](https://travis-ci.org/atom/symbols-view)

Display the list of functions/methods in the editor via `cmd-r` in Atom.

If your project has a `tags`/`.tags`/`TAGS`/`.TAGS` file at the root then
following are supported:

|Command|Description|Keybinding<br>(Linux)|Keybinding<br>(OS X)|Keybinding<br>(Windows)|
|-------|-----------|------------------|-----------------|--------------------|
|`symbols-view:toggle-file-symbols`|Show all symbols in current file|<kbd>Ctrl-r</kbd>|<kbd>Cmd-r</kbd>|<kbd>Ctrl-r</kbd>|
|`symbols-view:toggle-project-symbols`|Show all symbols in the project|<kbd>Ctrl-Shift-R</kbd>|<kbd>Cmd-Shift-R</kbd>|<kbd>Ctrl-Shift-R</kbd>|
|`symbols-view:go-to-declaration`|Jump to the symbol under the cursor|<kbd>Ctrl-Alt-Down</kbd>|<kbd>Cmd-Alt-Down</kbd>||
|`symbols-view:return-from-declaration`|Return from the jump|<kbd>Ctrl-Alt-Up</kbd>|<kbd>Cmd-Alt-Up</kbd>||

This package uses [ctags](http://ctags.sourceforge.net).

![](https://f.cloud.github.com/assets/671378/2241860/30ef0b2e-9ce8-11e3-86e2-2c17c0885fa4.png)
