SHELL := /bin/bash
DEST := /var/www/html/
DATE := $(shell date "+%Y%m%d%H%M%S")

deploy:
	rsync -rC \
		`pwd`/ui/* \
		lenni@byvekstavtale.leonard.io:${DEST}

