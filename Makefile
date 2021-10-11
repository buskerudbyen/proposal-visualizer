SHELL := /bin/bash
DEST := /var/www/html/
DATE := $(shell date "+%Y%m%d%H%M%S")

.PHONY: ansible

deploy:
	rsync -rC \
		`pwd`/ui/* \
		lenni@byvekstavtale.leonard.io:${DEST}

ansible:
	cd ansible && make production
