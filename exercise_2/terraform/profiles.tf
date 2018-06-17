resource "matchbox_profile" "coreos-install" {
  name   = "container-linux-install"
  kernel = "${var.matchbox_http_endpoint}/assets/coreos/${var.container_linux_version}/coreos_production_pxe.vmlinuz"

  initrd = [
    "${var.matchbox_http_endpoint}/assets/coreos/${var.container_linux_version}/coreos_production_pxe_image.cpio.gz",
  ]

  args = [
      "coreos.config.url=${var.matchbox_http_endpoint}/ignition?uuid=$${uuid}&mac=$${mac:hexhyp}",
      "coreos.first_boot=yes",
      "coreos.autologin=tty1",
      "initrd=coreos_production_pxe_image.cpio.gz",
      "systemd.log_level=debug",
      "console=tty0",
      "console=ttyS0",
      "BOOT_DEBUG=3",
      "debug=vnc",
  ]

  container_linux_config = "${file("./cl/coreos-install.yaml.tmpl")}"
}

// Create a simple profile which just sets an SSH authorized_key
resource "matchbox_profile" "simple" {
  name                   = "simple"
  container_linux_config = "${file("./cl/simple.yaml.tmpl")}"
}
