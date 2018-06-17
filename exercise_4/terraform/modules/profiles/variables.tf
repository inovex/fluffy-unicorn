variable "matchbox_http_endpoint" {
  type        = "string"
  description = "Matchbox HTTP read-only endpoint (e.g. http://matchbox.example.com:8080)"
}

variable "container_linux_version" {
  type        = "string"
  description = "Container Linux version of the kernel/initrd to PXE or the image to install"
}

variable "kubernetes_major_version" {
  type        = "string"
  description = "Kubernetes major version. For example: The major version of kubernetes 1.7.8 is 1.7"
}
