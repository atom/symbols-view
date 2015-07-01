# Symbols View package [![Build Status](https://travis-ci.org/atom/symbols-view.svg?branch=master)](https://travis-ci.org/atom/symbols-view)

Display the list of functions/methods in the editor via `cmd-r` in Atom.

If your project has a `tags`/`.tags`/`TAGS`/`.TAGS` file at the root then
following are supported:

  * <kbd>cmd-r</kbd> to view all function/methods in the current file

  * <kbd>cmd-shift-r</kbd> to view all function/methods in the project

  * <kbd>ctrl-alt-down</kbd> to jump to the declaration of the method/function under
    the cursor

  * <kbd>ctrl-alt-up</kbd> to return from the jump

This package uses [ctags](http://ctags.sourceforge.net).

![](https://f.cloud.github.com/assets/671378/2241860/30ef0b2e-9ce8-11e3-86e2-2c17c0885fa4.png)
