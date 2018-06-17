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
/*resource "matchbox_group" "simple-install" {
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
*/

// Match machines which have CoreOS Container Linux installed and has the MAC 52:54:00:fb:53:a6
resource "matchbox_group" "master-install" {
  name    = "master-install"
  profile = "${matchbox_profile.simple.name}"

  selector {
    os  = "installed"
    mac = "52:54:00:fb:53:a6"
  }

  metadata {
    ssh_authorized_key  = "${var.ssh_authorized_key}"
    content             = "I'm a master"
  }
}

// Match machines which have CoreOS Container Linux installed and has the MAC 52:54:00:fb:53:a9
resource "matchbox_group" "worker-install" {
  name    = "worker-install"
  profile = "${matchbox_profile.simple.name}"

  selector {
    os  = "installed"
    mac = "52:54:00:fb:53:a9"
  }

  metadata {
    ssh_authorized_key  = "${var.ssh_authorized_key}"
    content             = "I'm a worker"
  }
}
