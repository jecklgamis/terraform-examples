default:
	cat ./Makefile
build:
	packer validate packer.json && packer build packer.json
test-ansible:
	cd ansible && ansible-playbook -i inventory.yml playbook.yml -b

