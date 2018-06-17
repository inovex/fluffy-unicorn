// Create common profiles
module "profiles" {
  source                    = "../profiles"
  matchbox_http_endpoint    = "${var.matchbox_http_endpoint}"
  container_linux_version   = "${var.container_linux_version}"
  kubernetes_major_version  = "${join(".",slice(split(".",var.kubernetes_version), 0, 2))}"
}
