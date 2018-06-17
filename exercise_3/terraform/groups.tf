// Default matcher group for machines
resource "matchbox_group" "default" {
  name    = "default"
  profile = "${matchbox_profile.coreos-install.name}"

  # no selector means all machines can be matched
  metadata {
    ignition_endpoint       = "${var.matchbox_http_endpoint}/ignition"
    ssh_authorized_key      = "${var.ssh_authorized_key}"
    baseurl_flag            = "-b ${var.matchbox_http_endpoint}/assets/coreos"
    container_linux_version = "${var.container_linux_version}"
    cmdb_url                = "${var.cmdb_url}"
    cmdb_user               = "${var.cmdb_user}"
    cmdb_password           = "${var.cmdb_password}"
  }
}

// Match machines which have CoreOS Container Linux installed
resource "matchbox_group" "simple-install" {
  name    = "simple-install"
  profile = "${matchbox_profile.simple.name}"

  selector {
    os = "installed"
  }

  metadata {
    ssh_authorized_key  = "${var.ssh_authorized_key}"
    content             = "We are all the same"
  }
}
