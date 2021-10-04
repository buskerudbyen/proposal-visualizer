.PHONY: vagrant staging production tileserver infrastructure
.PRECIOUS: tileserver/%.osm.pbf

# ansible

PLAYBOOK_CMD:=ANSIBLE_PIPELINING=true ansible-playbook --vault-password-file vault-password

galaxy-install:
	ansible-galaxy install -r requirements.yml

galaxy-install-force:
	ansible-galaxy install --force -r requirements.yml

production: galaxy-install
	${PLAYBOOK_CMD} -i production proposal-visualizer.yml

