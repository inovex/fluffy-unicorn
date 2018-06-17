provider "matchbox" {
  endpoint    = "${var.matchbox_rpc_endpoint}"
  client_cert = "${file("/etc/matchbox/client.crt")}"
  client_key  = "${file("/etc/matchbox/client.key")}"
  ca          = "${file("/etc/matchbox/ca.crt")}"
}
