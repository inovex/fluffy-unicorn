-include .env
make env-file:
	@cp env.tmpl .env
	@sed "s/.*CL_VERSION=.*/CL_VERSION=$(shell ./scripts/get_cluster_yaml_value.sh container_linux_version)/" -i .env
	@sed "s/.*K8S_VERSION=.*/K8S_VERSION=$(shell ./scripts/get_cluster_yaml_value.sh kubernetes_version)/" -i .env
	@sed "s/.*CT_VERSION=.*/CT_VERSION=$(shell ./scripts/get_cluster_yaml_value.sh consul_template_version)/" -i .env
	@sed "s/.*VAULT_CERT_TTL=.*/VAULT_CERT_TTL=$(shell ./scripts/get_cluster_yaml_value.sh cert_ttl)/" -i .env
	@sed -e 's/^/export /' -i .env

pxe_server: env-file
	@# Required to not fail on first start after a reboot
	vagrant up --no-provision --provider $(VAGRANT_PROVIDER)
	vagrant ssh pxe_server -c "sudo apt-get -qq install -y rsync && sudo mkdir -p /var/lib/matchbox/assets/"
	rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.vagrant.d/insecure_private_key" \
		--rsync-path="sudo rsync" \
		$(shell pwd)/.env vagrant@192.168.0.254:/etc/environment

	rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.vagrant.d/insecure_private_key" \
		--rsync-path="sudo rsync"  \
		$(HOME)/.vagrant.d/insecure_private_key vagrant@192.168.0.254:/home/vagrant/insecure_private_key
	vagrant ssh pxe_server -c 'sudo chown vagrant:vagrant insecure_private_key'

	# We need the assets file in the matchbox server script
	rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.vagrant.d/insecure_private_key" \
		--rsync-path="sudo rsync" \
		$(shell pwd)/data/fluffy-unicorn-ka-assets.yaml vagrant@192.168.0.254:/var/lib/matchbox/assets/fluffy-unicorn-ka-assets.yaml

	vagrant provision
	make confd_config
	make etcd_data
	make download_assets
	make terraform_config

confd_config:
	@#vagrant rsync doesn't work and the 9p filesystem seems to have some issues as well,
	@#so we just manually rsync the confd templates and config
	rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.vagrant.d/insecure_private_key" \
		--rsync-path="sudo rsync" \
		$(shell pwd)/confd/ vagrant@192.168.0.254:/etc/confd/

etcd_data:
	# Image can be found here: https://hub.docker.com/r/johscheuer/etcdtool/
	docker run --rm -ti -v $$(pwd)/data/:/data -w /data johscheuer/etcdtool:latest "echo '$(ETCD_PASS)' | etcdtool -u $(ETCD_USER) -p $(ETCD_URL) import -y -f 'YAML' / fluffy-unicorn-ka-assets.yaml" > /dev/null
	docker run --rm -ti -v $$(pwd)/data/:/data -w /data johscheuer/etcdtool:latest "echo '$(ETCD_PASS)' | etcdtool -u $(ETCD_USER) -p $(ETCD_URL) import -y -f 'YAML' / cluster/fluffy-unicorn-ka.yaml" > /dev/null

	# Add AppRole ID's for master and worker
	curl --fail -Ss -u $(ETCD_USER):$(ETCD_PASS) $(ETCD_URL)/v2/keys/inovex/k8s/clusters/$(CLUSTER_NAME)/defaults/master_app_role_id -XPUT --data value="$(shell vagrant ssh pxe_server -c "cat /tmp/app_roles/master_id" | tr -d '[:space:]')" > /dev/null
	curl --fail -Ss -u $(ETCD_USER):$(ETCD_PASS) $(ETCD_URL)/v2/keys/inovex/k8s/clusters/$(CLUSTER_NAME)/defaults/worker_app_role_id -XPUT --data value="$(shell vagrant ssh pxe_server -c "cat /tmp/app_roles/worker_id" | tr -d '[:space:]')" > /dev/null

cluster: confd_config etcd_data download_assets terraform_config
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
	vagrant ssh pxe_server -c "sudo sed -i s/REPLACE_VIA_PIPELINE_WITH_GIT_REFERENCE/$(shell git rev-parse --short HEAD)/g /etc/terraform/modules/kubernetes/groups.tf"
	vagrant ssh pxe_server -c 'sudo systemctl start confd-terraform.service'
	# Validate that everything worked
	curl -s --fail "http://192.168.0.254:8080/ignition?mac=52-54-00-fb-53-a6" > /dev/null
	curl -s --fail "http://192.168.0.254:8080/ignition?mac=52-54-00-fb-53-a6&os=installed" > /dev/null
	@# Fail if data is missing
	vagrant ssh pxe_server -c 'if grep -q NOT_FOUND_IN_STORE /etc/terraform/clusters.tf; then echo "Error: Missing data in clusters.tf!"; exit 1; fi'

download_assets:
	rsync -ravz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.vagrant.d/insecure_private_key" \
		--rsync-path="sudo rsync" \
		$(shell pwd)/scripts/asset-downloader/ vagrant@192.168.0.254:/opt/bin/
	vagrant ssh pxe_server -c /bin/bash -c "sudo LAST_N_RELEASES=1 /opt/bin/asset-downloader && sudo chown -R matchbox:matchbox /var/lib/matchbox/"

setup_kubectl:
	@./scripts/setup_kubectl.sh
	kubectl --kubeconfig .kube/config get nodes
