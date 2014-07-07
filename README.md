# Atom Ctags Package

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
* ~~use Activation Events to speed up load time~~
* ~~use ctags command args -R~~


#Changelog
* go-to-declaration support column
* Optimization for duplicate results [#3](https://github.com/yongkangchen/atom-ctags/issues/3)
* [speed tag parse by use ctag command param to parse line number instead of fs-plus](https://github.com/yongkangchen/atom-ctags/commit/784160320309212d0acf865092133ba55980c605)
* [`use -R instead of (fs-plus).traverseTreeSync` and `search tag limit max`](https://github.com/yongkangchen/atom-ctags/commit/4e4df478c2a00b83143e1887a8b6fd6c5067ce95)
* 
