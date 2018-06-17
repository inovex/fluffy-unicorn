-include .env
make env-file:
	@cp env.tmpl .env
	@sed -e 's/^/export /' -i .env

pxe_server: env-file
	@# Required to not fail on first start after a reboot
	vagrant up --no-provision --provider $(VAGRANT_PROVIDER)
	vagrant ssh pxe_server -c "sudo apt-get install -y rsync"
	rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.vagrant.d/insecure_private_key" \
		--rsync-path="sudo rsync" \
		$(shell pwd)/.env vagrant@192.168.0.254:/etc/environment

	rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.vagrant.d/insecure_private_key" \
		--rsync-path="sudo rsync"  \
		$(HOME)/.vagrant.d/insecure_private_key vagrant@192.168.0.254:/home/vagrant/insecure_private_key
	vagrant ssh pxe_server -c 'sudo chown vagrant:vagrant insecure_private_key'

	vagrant provision
	make terraform_config

cluster: terraform_config
	# We need the until because there are some issues with VBox and PXE boot
	until VAGRANT_VAGRANTFILE=vagrantfile_client vagrant up --no-provision --parallel; do echo "Booting up all machines"; done

destroy_cluster:
	VAGRANT_VAGRANTFILE=vagrantfile_client vagrant destroy -f || true

clean: destroy_cluster
	vagrant destroy -f || true

terraform_config:
	@#vagrant rsync doesn't work and the 9p filesystem seems to have some issues as well,
	@#so we just manually rsync the confd templates and config
	rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.vagrant.d/insecure_private_key" \
		--rsync-path="sudo rsync" \
		$(shell pwd)/terraform/* vagrant@192.168.0.254:/etc/terraform/
	vagrant ssh pxe_server -c 'cd /etc/terraform && sudo terraform init && sudo terraform plan && sudo terraform apply --auto-approve'
	# Validate that everything worked
	curl -s --fail "http://192.168.0.254:8080/ignition?mac=52-54-00-fb-53-a6" > /dev/null
	curl -s --fail "http://192.168.0.254:8080/ignition?mac=52-54-00-fb-53-a6&os=installed" > /dev/null
