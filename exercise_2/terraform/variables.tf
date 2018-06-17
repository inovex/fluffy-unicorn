variable "matchbox_rpc_endpoint" {
  type        = "string"
  description = "Matchbox gRPC API endpoint, without the protocol (e.g. matchbox.example.com:8081)"
}

variable "ssh_authorized_key" {
  type        = "string"
  description = "SSH public key to set as an authorized_key on machines"
}

variable "matchbox_http_endpoint" {
  type        = "string"
  description = "Matchbox HTTP read-only endpoint (e.g. http://matchbox.example.com:8080)"
}

variable "container_linux_version" {
  type        = "string"
  description = "Container Linux version which should be deployed"
}

variable "cmdb_url" {
  type        = "string"
  description = "URL to the etcd CMDB"
}

variable "cmdb_password" {
  type        = "string"
  description = "Password to authenticate against the etcd"
}

variable "cmdb_user" {
  type        = "string"
  description = "User to authenticate against the etcd"
}
