SHELL := /bin/bash
DEST := /var/www/html/
DATE := $(shell date "+%Y%m%d%H%M%S")

.PHONY: ansible tilemaker icons

deploy:
	rsync -rC \
		`pwd`/ui/* \
		lenni@byvekstavtale.leonard.io:${DEST}

ansible:
	cd ansible && make production

tilemaker/norway.osm.pbf:
	curl --create-dirs --fail https://download.geofabrik.de/europe/norway-latest.osm.pbf -o $@

tilemaker/drammen.osm.pbf: tilemaker/norway.osm.pbf
	osmium extract tilemaker/norway.osm.pbf --polygon ansible/roles/tilemaker/templates/buskerudbyen-and-around.geojson -o $@

tilemaker: tilemaker/drammen.osm.pbf icons
	cp ansible/roles/tilemaker/templates/bicycle/* tilemaker
	jq '. | .settings.filemetadata.tiles=["http://localhost:8123/{z}/{x}/{y}.pbf"]' tilemaker/config-openmaptiles.json > tilemaker/temp.json
	mv tilemaker/temp.json tilemaker/config-openmaptiles.json

	podman run \
		-it \
		-v $(PWD)/tilemaker/:/srv:z \
		--name tilemaker-map \
		--rm \
		docker.io/stadtnavi/tilemaker:a3c70afb7685cb642da8424eba9863ca37bbc32c\
		/srv/drammen.osm.pbf \
		--output=/srv/tiles/  \
		--config=/srv/config-openmaptiles.json \
		--process=/srv/process-openmaptiles.lua

	cp ansible/roles/tilemaker/files/* tilemaker/tiles

	cp ansible/roles/tilemaker/templates/bicycle/index.html tilemaker/tiles
	jq '. | .sources.openmaptiles.url="http://localhost:8123/metadata.json" | .sprite="http://localhost:8123/sprite"' ansible/roles/tilemaker/templates/bicycle/style.json > tilemaker/tiles/style.json

	python3 -m http.server 8123 --directory tilemaker/tiles/


icons:
	spritezero ansible/roles/tilemaker/files/sprite icons
	spritezero --retina ansible/roles/tilemaker/files/sprite@2x icons
