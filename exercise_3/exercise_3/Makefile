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
	make confd_config

confd_config: etcd_data
	@#vagrant rsync doesn't work and the 9p filesystem seems to have some issues as well,
	@#so we just manually rsync the confd templates and config
	rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.vagrant.d/insecure_private_key" \
		--rsync-path="sudo rsync" \
		$(shell pwd)/confd/ vagrant@192.168.0.254:/etc/confd/

etcd_data:
	curl --fail -Ss -u $(ETCD_USER):$(ETCD_PASS) http://192.168.0.254:2379/v2/keys/nodes/kmaster-fluffy-unicorn-az01-001/mac -XPUT --data value="52:54:00:fb:53:a6" > /dev/null
	curl --fail -Ss -u $(ETCD_USER):$(ETCD_PASS) http://192.168.0.254:2379/v2/keys/nodes/kmaster-fluffy-unicorn-az01-001/ip_address -XPUT --data value="192.168.1.2" > /dev/null
	curl --fail -Ss -u $(ETCD_USER):$(ETCD_PASS) http://192.168.0.254:2379/v2/keys/nodes/kmaster-fluffy-unicorn-az01-001/deploy -XPUT --data value="initial" > /dev/null
	curl --fail -Ss -u $(ETCD_USER):$(ETCD_PASS) http://192.168.0.254:2379/v2/keys/nodes/kworker-fluffy-unicorn-az01-001/mac -XPUT --data value="52:54:00:fb:53:a9" > /dev/null
	curl --fail -Ss -u $(ETCD_USER):$(ETCD_PASS) http://192.168.0.254:2379/v2/keys/nodes/kworker-fluffy-unicorn-az01-001/ip_address -XPUT --data value="192.168.1.3" > /dev/null
	curl --fail -Ss -u $(ETCD_USER):$(ETCD_PASS) http://192.168.0.254:2379/v2/keys/nodes/kworker-fluffy-unicorn-az01-001/deploy -XPUT --data value="initial" > /dev/null

cluster: terraform_config etcd_data
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
	# Validate that everything worked
	vagrant ssh pxe_server -c 'cd /etc/terraform && sudo terraform plan && sudo terraform apply'
	vagrant ssh pxe_server -c 'curl -s --fail "http://localhost:8080/ignition?mac=52-54-00-fb-53-a6" > /dev/null'
	vagrant ssh pxe_server -c 'curl -s --fail "http://localhost:8080/ignition?mac=52-54-00-fb-53-a6&os=installed" > /dev/null'
