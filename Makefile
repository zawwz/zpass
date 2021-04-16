
var_exclude = ZPASS_.* XDG_.* REMOTE_.* DISPLAY CONFIGFILE TMPDIR
fct_exclude = _tty_on

zpass: src/*
	lxsh -o zpass -M --exclude-var "$(var_exclude)" --exclude-fct "$(fct_exclude)" src/main.sh

debug: src/*
	lxsh -o zpass src/main.sh

build: zpass

install: build
	mv zpass /usr/local/bin

uninstall:
	rm /usr/local/bin/zpass

clear:
	rm zpass
