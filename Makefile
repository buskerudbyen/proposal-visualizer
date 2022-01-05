SHELL := /bin/bash
DEST := /var/www/html/
DATE := $(shell date "+%Y%m%d%H%M%S")

.PHONY: ansible tilemaker

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

tilemaker: tilemaker/drammen.osm.pbf
	cp ansible/roles/tilemaker/templates/bicycle/* tilemaker
	jq '. | .settings.filemetadata.tiles=["http://localhost:8123/tiles/"]' tilemaker/config-openmaptiles.json > tilemaker/temp.json
	mv tilemaker/temp.json tilemaker/config-openmaptiles.json
	podman run \
		-it \
		-v $(PWD)/tilemaker/:/srv:z \
		--name tilemaker-map \
		--rm \
		docker.io/stadtnavi/tilemaker:2f617ccb1aa49ecda2685a4721361a479f0b6b81 \
		/srv/drammen.osm.pbf \
		--output=/srv/tiles/  \
		--config=/srv/config-openmaptiles.json \
		--process=/srv/process-openmaptiles.lua \

