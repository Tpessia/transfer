SHELL := /bin/bash

vagrant_vagrantfile = deploy/systemd.Vagrantfile
vagrant_dotfile_path = ./.vagrant
vagrant_vars = VAGRANT_VAGRANTFILE=$(vagrant_vagrantfile) VAGRANT_DOTFILE_PATH=$(vagrant_dotfile_path)

machine ?= systemd

vagrant-status:
	$(vagrant_vars) vagrant status

vagrant-up:
	$(vagrant_vars) vagrant up --no-parallel --provider libvirt

vagrant-connect:
	$(vagrant_vars) vagrant ssh $(machine) -- -t 'cd /vagrant; /bin/bash'

vagrant-reload:
	$(vagrant_vars) vagrant reload

vagrant-halt:
	$(vagrant_vars) vagrant halt

vagrant-destroy:
	$(vagrant_vars) vagrant destroy -f