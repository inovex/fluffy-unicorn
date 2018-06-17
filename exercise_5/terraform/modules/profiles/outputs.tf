output "container-linux-install" {
  value = "${matchbox_profile.container-linux-install.name}"
}

output "kube-controller" {
  value = "${matchbox_profile.kube-controller.name}"
}

output "kube-worker" {
  value = "${matchbox_profile.kube-worker.name}"
}
