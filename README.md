# Atom Ctags Package (Beta version, not statable)

This package uses：
[ctags](http://ctags.sourceforge.net),
[autocomplete-plus](https://github.com/saschagehlich/autocomplete-plus)
and fork from [symbols-view](https://github.com/atom/symbols-view)

#Features
* **AutoComplete with ctags**
* **Auto Update the file's tags data when saved**
* go-to-declaration and return-from-declaration
* toggle-file-symbols
* "Rebuild Ctags" in context-menu
* "Auto Build Tags When Active" in Settings, default: false

![atom-ctags](https://cloud.githubusercontent.com/assets/704762/3483867/e0bac2ee-0397-11e4-89c1-70689f6b8ff3.gif)

#Install
**You can install atom-ctags using the Preferences pane.**

autocomplete with ctags dependent on [autocomplete-plus](https://github.com/saschagehlich/autocomplete-plus) already installed.


#TODO
* ~~Submit to atom package center~~
* ~~Modify package name~~
* Performance optimization
* Disk file cache
* Release memory when deactivate
* Appearance improve
* Writing Tests
* Auto check package of autocomplete-plus installed
* ~~Auto disable package of symbols-view~~
* use Activation Events to speed up load time
* ~~use ctags command args -R~~


#Changelog
*go-to-declaration support column
