// Install Container Linux to disk
resource "matchbox_group" "container-linux-install" {
  count = "${length(var.controller_names) + length(var.worker_names)}"

  name    = "${format("container-linux-install-%s", element(concat(var.controller_names, var.worker_names), count.index))}"
  profile = "${module.profiles.container-linux-install}"

  selector {
    mac = "${element(concat(var.controller_macs, var.worker_macs), count.index)}"
  }

  metadata {
    container_linux_channel                 = "${var.container_linux_channel}"
    container_linux_version                 = "${var.container_linux_version}"
    ignition_endpoint                       = "${format("%s/ignition", var.matchbox_http_endpoint)}"
    install_disk                            = "${var.install_disk}"
    #data_disk                               = "${var.data_disk}"
    cmdb_url                                = "${var.cmdb_url}"
    # profile uses -b baseurl to install from matchbox cache
    baseurl_flag                            = "-b ${var.matchbox_http_endpoint}/assets/coreos"

    assets_host                             = "${format("%s/assets", var.matchbox_http_endpoint)}"

    vault_url                               = "${var.vault_url}"
    vault_tls_enabled                       = "${var.vault_tls_enabled}"
    # We don't know if the node is a worker or a controller, thus we use the approle
    # id with less permissisions
    vault_approle_id                        = "${var.vault_approle_id_worker}"
    cluster_name                            = "${var.cluster_name}"

    # Constants used to ensure SSOT
    consultemplate_version                  = "${var.consultemplate_version}"
    consultemplate_sha512                   = "${var.consultemplate_sha512}"
    consultemplate_config                   = "/etc/consul-template/config.hcl"
    consultemplate_vault_token_file         = "/etc/consul-template/vault_token"

    consultemplate_cmdbcreds_template       = "/etc/consul-template/cmdb_credentials.tmpl"
    consultemplate_cmdbcreds_rendered       = "/etc/cmdb_credentials.env"
  }
}

resource "matchbox_group" "controller" {
  count   = "${length(var.controller_names)}"
  name    = "${format("%s.%s", element(var.controller_names, count.index), var.cluster_domain)}"

  profile = "${module.profiles.kube-controller}"

  selector {
    mac = "${element(var.controller_macs, count.index)}"
    os  = "installed"
  }

  metadata {
    git_reference                           = "REPLACE_VIA_PIPELINE_WITH_GIT_REFERENCE"
    cluster_name                            = "${var.cluster_name}"
    controller_name                         = "${format("%s.%s", element(var.controller_names, count.index), var.cluster_domain)}"
    controller_ips                          = "${join(" ", var.controller_ips)}"
    etcd_version                            = "${var.etcd_version}"
    etcd_initial_cluster                    = "${join(",", formatlist("%s.%s=https://%s.%s:2380", var.controller_names, var.cluster_domain, var.controller_names, var.cluster_domain))}"
    etcd_cluster                            = "${join(",", formatlist("https://%s.%s:2379", var.controller_names, var.cluster_domain))}"

    kubernetes_version                      = "${var.kubernetes_version}"
    k8s_dns_service_ip                      = "${var.kube_dns_service_ip}"
    k8s_api_service_ip                      = "${var.api_service_ip}"
    k8s_api_server_port                     = "${var.api_server_port}"
    k8s_service_cidr                        = "${var.service_cidr}"
    k8s_pod_cidr                            = "${var.pod_cidr}"
    k8s_api_servers                         = "${join(",", formatlist("https://%s.%s", var.controller_names, var.cluster_domain))}"
    k8s_api_server_count                    = "${length(var.controller_names)}"
    k8s_scheduler_kubeconfig                = "/var/lib/kubernetes/scheduler"
    k8s_controller_manager_kubeconfig       = "/var/lib/kubernetes/controller-manager"
    k8s_domain_name                         = "${var.k8s_domain_name}"
    k8s_api_server_ha_address               = "${var.api_server_ha_address}"
    k8s_api_server_vip_address              = "${var.api_server_vip_address}"
    k8s_base_dir                            = "${var.kubernetes_base_dir}"
    k8s_service_account_private_key         = "${var.kubernetes_base_dir}/service_account_key.key"

    assets_host                             = "${format("%s/assets", var.matchbox_http_endpoint)}"

    vault_url                               = "${var.vault_url}"
    vault_tls_enabled                       = "${var.vault_tls_enabled}"
    vault_approle_id                        = "${var.vault_approle_id_master}"
    cmdb_url                                = "${var.cmdb_url}"

    domain                                  = "${var.cluster_domain}"

    mtu                                     = "${var.mtu}"
    infra_pod                               = "${var.infra_pod}"

    # Constants used to assert ssot
    node_env_file                           = "/etc/node.env"

    consultemplate_version                  = "${var.consultemplate_version}"
    consultemplate_sha512                   = "${var.consultemplate_sha512}"
    consultemplate_sa_keytemplate           = "/etc/consul-template/sa_key.tmpl"
    consultemplate_cmdb_config              = "/etc/consul-template/config-cmdb.hcl"
    consultemplate_cmdbcreds_template       = "/etc/consul-template/cmdb_credentials.tmpl"
    consultemplate_cmdbcreds_rendered       = "/etc/cmdb_credentials.env"

    ampua_consultemplate_config             = "/etc/ampua/consul-template.hcl"
    ampua_credentialfile                    = "/etc/ampua/credentials"
    ampua_vault_token_file                  = "/etc/ampua/vault_token"
    check_debug_scriptlocation              = "/opt/bin/check-debug"

    consultemplate_config                   = "/etc/consul-template/config.hcl"
    consultemplate_vault_token_file         = "/etc/consul-template/vault_token"

    consultemplate_etcd_catemplate          = "/etc/consul-template/etcd_ca.tmpl"
    consultemplate_etcd_crttemplate         = "/etc/consul-template/etcd_crt.tmpl"
    consultemplate_etcd_keytemplate         = "/etc/consul-template/etcd_key.tmpl"

    consultemplate_k8s_catemplate           = "/etc/consul-template/k8s_ca.tmpl"
    consultemplate_api_crttemplate          = "/etc/consul-template/api_crt.tmpl"
    consultemplate_api_keytemplate          = "/etc/consul-template/api_key.tmpl"
    consultemplate_controllerm_crttemplate  = "/etc/consul-template/cm_crt.tmpl"
    consultemplate_controllerm_keytemplate  = "/etc/consul-template/cm_key.tmpl"
    consultemplate_scheduler_crttemplate    = "/etc/consul-template/scheduler_crt.tmpl"
    consultemplate_scheduler_keytemplate    = "/etc/consul-template/scheduler_key.tmpl"

    etcd_cafile                             = "/etc/etcd/ca.pem"
    etcd_crtfile                            = "/etc/etcd/crt.pem"
    etcd_keyfile                            = "/etc/etcd/key.pem"

    k8s_cafile                              = "${var.kubernetes_base_dir}/ca.pem"
    api_crtfile                             = "${var.kubernetes_base_dir}/api_crt.pem"
    api_keyfile                             = "${var.kubernetes_base_dir}/api_key.pem"
    controllerm_crtfile                     = "${var.kubernetes_base_dir}/cm_crt.pem"
    controllerm_keyfile                     = "${var.kubernetes_base_dir}/cm_key.pem"
    scheduler_crtfile                       = "${var.kubernetes_base_dir}/scheduler_crt.pem"
    scheduler_keyfile                       = "${var.kubernetes_base_dir}/scheduler_key.pem"

    consultemplate_kubelet_crttemplate      = "/etc/consul-template/kubelet_crt.tmpl"
    consultemplate_kubelet_keytemplate      = "/etc/consul-template/kubelet_key.tmpl"
    kubelet_crtfile                         = "${var.kubernetes_base_dir}/kubelet_crt.pem"
    kubelet_keyfile                         = "${var.kubernetes_base_dir}/kubelet_key.pem"

    consultemplate_kube_proxy_crttemplate   = "/etc/consul-template/kube_proxy_crt.tmpl"
    consultemplate_kube_proxy_keytemplate   = "/etc/consul-template/kube_proxy_key.tmpl"
    kube_proxy_crtfile                      = "${var.kubernetes_base_dir}/kube_proxy_crt.pem"
    kube_proxy_keyfile                      = "${var.kubernetes_base_dir}/kube_proxy_key.pem"

    label_node_scriptlocation               = "/opt/bin/label_node"
    write_hostname_scriptlocation           = "/opt/bin/write_hostname"
    kubelet_kubeconfig                      = "/var/lib/kubernetes/kubelet_kubeconfig"
    kube_proxy_kubeconfig                   = "/var/lib/kubernetes/kube_proxy_kubeconfig"
    kube_proxy_config_writer                = "/opt/bin/kube_proxy_config_writer"
    kube_proxy_config                       = "${var.kubernetes_base_dir}/kube_proxy_conf.yaml"

    check_deploy_scriptlocation             = "/opt/bin/check-deploy"
    write_failure_domain_scriptlocation     = "/opt/bin/write-failure-domains"
    haproxy_configwriter_scriptlocation     = "/opt/bin/haproxy_configwriter"
    haproxy_port                            = "11000"

    master_eviction                         = "${var.master_eviction}"
    master_kube_reserved                    = "${var.master_kube_reserved}"
    master_sys_reserved                     = "${var.master_sys_reserved}"

    sshd_config_script                      = "/opt/bin/sshd_config_writer"

    cert_ttl                                = "${var.cert_ttl}"
  }
}

resource "matchbox_group" "worker" {
  count   = "${length(var.worker_names)}"
  name    = "${format("%s.%s", element(var.worker_names, count.index), var.cluster_domain)}"

  profile = "${module.profiles.kube-worker}"

  selector {
    mac = "${element(var.worker_macs, count.index)}"
    os  = "installed"
  }

  metadata {
    git_reference                             = "REPLACE_VIA_PIPELINE_WITH_GIT_REFERENCE"
    cluster_name                              = "${var.cluster_name}"
    kubernetes_version                        = "${var.kubernetes_version}"
    k8s_dns_service_ip                        = "${var.kube_dns_service_ip}"
    k8s_domain_name                           = "${var.k8s_domain_name}"
    k8s_pod_cidr                              = "${var.pod_cidr}"
    k8s_api_server_ha_address                 = "${var.api_server_ha_address}"
    k8s_api_server_vip_address                = "${var.api_server_vip_address}"
    k8s_api_server_port                       = "${var.api_server_port}"
    k8s_base_dir                              = "${var.kubernetes_base_dir}"
    controller_ips                            = "${join(" ", var.controller_ips)}"

    assets_host                               = "${format("%s/assets", var.matchbox_http_endpoint)}"

    vault_url                                 = "${var.vault_url}"
    vault_tls_enabled                         = "${var.vault_tls_enabled}"
    vault_approle_id                          = "${var.vault_approle_id_worker}"
    cmdb_url                                  = "${var.cmdb_url}"

    domain                                    = "${var.cluster_domain}"

    mtu                                       = "${var.mtu}"
    infra_pod                                 = "${var.infra_pod}"
    # Constants used to assert ssot
    node_env_file                             = "/etc/node.env"

    consultemplate_version                    = "${var.consultemplate_version}"
    consultemplate_sha512                     = "${var.consultemplate_sha512}"
    consultemplate_cmdb_config                = "/etc/consul-template/config-cmdb.hcl"
    consultemplate_cmdbcreds_template         = "/etc/consul-template/cmdb_credentials.tmpl"
    consultemplate_cmdbcreds_rendered         = "/etc/cmdb_credentials.env"

    ampua_consultemplate_config               = "/etc/ampua/consul-template.hcl"
    ampua_credentialfile                      = "/etc/ampua/credentials"
    ampua_vault_token_file                    = "/etc/ampua/vault_token"
    check_debug_scriptlocation                = "/opt/bin/check-debug"

    consultemplate_config                     = "/etc/consul-template/config.hcl"
    consultemplate_vault_token_file           = "/etc/consul-template/vault_token"

    consultemplate_k8s_catemplate             = "/etc/consul-template/k8s_ca.tmpl"
    consultemplate_kubelet_crttemplate        = "/etc/consul-template/kubelet_crt.tmpl"
    consultemplate_kubelet_keytemplate        = "/etc/consul-template/kubelet_key.tmpl"
    k8s_cafile                                = "${var.kubernetes_base_dir}/ca.pem"
    kubelet_crtfile                           = "${var.kubernetes_base_dir}/kubelet_crt.pem"
    kubelet_keyfile                           = "${var.kubernetes_base_dir}/kubelet_key.pem"

    consultemplate_kube_proxy_crttemplate     = "/etc/consul-template/kube_proxy_crt.tmpl"
    consultemplate_kube_proxy_keytemplate     = "/etc/consul-template/kube_proxy_key.tmpl"
    kube_proxy_crtfile                        = "${var.kubernetes_base_dir}/kube_proxy_crt.pem"
    kube_proxy_keyfile                        = "${var.kubernetes_base_dir}/kube_proxy_key.pem"

    label_node_scriptlocation                 = "/opt/bin/label_node"
    write_hostname_scriptlocation             = "/opt/bin/write_hostname"

    kubelet_kubeconfig                        = "/var/lib/kubernetes/kubelet_kubeconfig"
    kube_proxy_kubeconfig                     = "/var/lib/kubernetes/kube_proxy_kubeconfig"
    kube_proxy_config_writer                  = "/opt/bin/kube_proxy_config_writer"
    kube_proxy_config                         = "${var.kubernetes_base_dir}/kube_proxy_conf.yaml"

    check_deploy_scriptlocation               = "/opt/bin/check-deploy"
    write_failure_domain_scriptlocation       = "/opt/bin/write-failure-domains"
    haproxy_configwriter_scriptlocation       = "/opt/bin/haproxy_configwriter"
    haproxy_port                              = "11000"
    node_eviction                             = "${var.node_eviction}"
    node_kube_reserved                        = "${var.node_kube_reserved}"
    node_sys_reserved                         = "${var.node_sys_reserved}"

    sshd_config_script                        = "/opt/bin/sshd_config_writer"

    cert_ttl                                  = "${var.cert_ttl}"
  }
}
