// Container Linux Install profile (from matchbox /assets cache)
// Note: Admin must have downloaded container_linux_version into matchbox assets.
resource "matchbox_profile" "container-linux-install" {
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

  container_linux_config = "${data.template_file.container-linux-install-config.rendered}"
}

data "template_file" "container-linux-install-config" {
  template = "${file("${path.module}/cl/container-linux-install.yaml.tmpl")}"
}

// Kubernetes controller profiler
resource "matchbox_profile" "kube-controller" {
  name                   = "kube-controller-${var.kubernetes_major_version}"
  container_linux_config =  "${file("${path.module}/cl/kube-controller-${var.kubernetes_major_version}.yaml.tmpl")}"
}

// Kubernetes worker profile
resource "matchbox_profile" "kube-worker" {
  name                   = "kube-worker-${var.kubernetes_major_version}"
  container_linux_config = "${file("${path.module}/cl/kube-worker-${var.kubernetes_major_version}.yaml.tmpl")}"
}
