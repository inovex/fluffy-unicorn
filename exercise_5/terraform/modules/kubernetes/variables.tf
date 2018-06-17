variable "matchbox_http_endpoint" {
  type        = "string"
  description = "Matchbox HTTP read-only endpoint (e.g. http://matchbox.example.com:8080)"
}

variable "container_linux_version" {
  type = "string"
  description = "Container Linux version of the kernel/initrd to PXE or the image to install"
}

variable "container_linux_channel" {
  type        = "string"
  description = "Container Linux channel corresponding to the container_linux_version"
}

variable "etcd_version" {
  type        = "string"
  description = "etcd version"
}

variable "etcd_sha512" {
  type        = "string"
  description = "sha512 sum of combined etcd and etcdctl"
}

variable "cluster_name" {
  type        = "string"
  description = "Name of the Kubernetes cluster"
}

variable "kubernetes_version" {
  type        = "string"
  description = "Kubernetes version"
}

variable "kubernetes_base_dir" {
  type        = "string"
  description = "Kubernetes base dir"
  default     = "/etc/k8s"
}

variable "api_server_ha_address" {
  type        = "string"
  description = "DNS Name for all API Servers"
}

variable "api_server_vip_address" {
  type        = "string"
  description = "VIP for all API Servers"
}

variable "api_server_port" {
  type        = "string"
  description = "HTTPs port for API Servers"
  default     = "443"
}

variable "api_service_ip" {
  type        = "string"
  description = "Kubernetes Service IP of the kubernetes.default service. Must be firsth ip from the service_cidr"
  default     = "10.3.0.1"
}

# CMDB Variables

variable "cmdb_url" {
  type        = "string"
  description = "Url of the cmdb endpoint used by nodes to set themselves deploy=false"
}

# Machines
# Terraform's crude "type system" does properly support lists of maps so we do this.

variable "controller_names" {
  type = "list"
}

variable "controller_macs" {
  type = "list"
}

variable "controller_ips" {
  type = "list"
}

variable "worker_names" {
  type = "list"
}

variable "worker_macs" {
  type = "list"
}

variable "cluster_domain" {
  description = "Domain name for the nodes inside the cluster"
  type        = "string"
}

variable "k8s_domain_name" {
  description = "Controller DNS name which resolves to a controller instance. Workers and kubeconfig's will communicate with this endpoint (e.g. cluster.example.com)"
  type        = "string"
}

variable "kube_dns_service_ip" {
  description = "Service IP for Kube DNS"
  type        = "string"
}

variable "pod_cidr" {
  description = "CIDR IP range to assign Kubernetes pods"
  type        = "string"
}

variable "service_cidr" {
  description = <<EOD
CIDR IP range to assign Kubernetes services.
The 1st IP will be reserved for kube_apiserver, the 10th IP will be reserved for kube-dns, the 15th IP will be reserved for self-hosted etcd, and the 200th IP will be reserved for bootstrap self-hosted etcd.
EOD

  type    = "string"
}

variable "install_disk" {
  type        = "string"
  description = "Disk device to which the install profiles should install Container Linux (e.g. /dev/sda)"
}

variable "vault_url" {
  type        = "string"
  description = "url of the vault server"
}

variable "vault_tls_enabled" {
  type        = "string"
  description = "Whether vault tls is enabled"
  default     = "true"
}

variable "vault_approle_id_master" {
  type        = "string"
  description = "Vault approle id used by masters to fetch their secret"
}

variable "vault_approle_id_worker" {
  type        = "string"
  description = "Vault approle id used by workers to fetch their secret"
}

variable "consultemplate_version" {
  type        = "string"
  description = "Version of consul-template"
}

variable "consultemplate_sha512" {
  type        = "string"
  description = "sha512sum of consul-template"
}

variable "mtu" {
  type        = "string"
  description = "MTU to configure for the default eth0 interface"
}

variable "master_eviction" {
  type        = "string"
  description = "Eviction threshold for masters"
}

variable "master_kube_reserved" {
  type        = "string"
  description = "Reserved resouces for the Kubernetes services on the masters"
}

variable "master_sys_reserved" {
  type        = "string"
  description = "Reserved resources for the system services on the masters"
}

variable "node_eviction" {
  type        = "string"
  description = "Eviction threshold for ndoes"
}

variable "node_kube_reserved" {
  type        = "string"
  description = "Reserved resouces for the Kubernetes services on the nodes"
}

variable "node_sys_reserved" {
  type        = "string"
  description = "Reserved resources for the system services on the nodes"
}

variable "cert_ttl" {
  type        = "string"
  description = "Certificate validation time"
}

variable infra_pod {
  type        = "string"
  default     = "gcr.io/google_containers/pause-amd64:3.1"
  description = "Infrastructure pod"
}
