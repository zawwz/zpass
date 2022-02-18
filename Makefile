
var_exclude = _ZPASS_.* ZPASS_.* XDG_.* REMOTE_.* DISPLAY CONFIGFILE TMPDIR DEBUG
fct_exclude = _stop sftp_cmd ftps_cmd upload download list delete create

zpass: src/*
	lxsh -o zpass -M --exclude-var "$(var_exclude)" --exclude-fct "$(fct_exclude)" src/main.sh

debug: src/*
	lxsh -o zpass src/main.sh

bash: src/*
	lxsh --bash -o zpass src/main.sh

build: zpass

install: build
	mv zpass /usr/local/bin
	cp completion/zpass.bash /etc/bash_completion.d

uninstall:
	rm /usr/local/bin/zpass
	rm /etc/bash_completion.d/zpass.bash

clear:
	rm zpass
