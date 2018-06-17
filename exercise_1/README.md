# Exercise 1

In this exercise we will start a Debian VM which acts as the [Matchbox](https://coreos.com/matchbox/docs/latest) and [DHCP server](https://www.isc.org/downloads/dhcp). All the configuration of Matchbox and the other components is done in a static manner. The provisioning scripts for the Matchbox VM can be found in `./scripts`.

## Starting Matchbox

```bash
make pxe_server
```

This will take a while until all components are successfully installed. In the mean time take a look at the provisioning script and the `Makefile`.

## Render Matchbox configuration

```bash
make terraform_config
```

This will copy all files from `./terraform` onto the Matchbox VM (into the folder `/etc/terraform`). In the next step the terraform configuration will be applied against the Matchbox. This step actually renders all the ignition templates and sets the groups according to the Matchbox selectors (we will get back to selectors in a later step). In the end we run two `curl` commands to validate that the configuration was applied successfully (since terraform can't tell us all errors e.g. a missing or bad configured ignition template).

## Deploy the new hosts

```bash
make cluster
```

This command will spin up two "blank" VM's that PXE boot from the Matchbox. Currently there is an issue with PXE boot, Vagrant and the VirtualBox Provider (because of this we need to set an Vagrant box image even we don't use it at all).

When you take a look into `./terraform/cl/coreos-install.yaml.tpml` you will notice that the machines won't reboot. If we would reboot our machines they would sick in a boot loop since our machines always boot from PXE and the Matchbox doesn't handle any state (e.g. is a machine already provisioned). We will get back to this topic in `exercise 2`.

## SSH into the new hosts

In order to ssh into the newly provisioned hosts you need to ssh into the `pxe_server` with `vagrant ssh pxe_server` now you can ssh into the other machines:

```bash
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i insecure_private_key core@192.168.1.2
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i insecure_private_key core@192.168.1.3
```

## Inspect the Machines

Verify that the installer runs successfully:

```bash
sudo journalctl -fu installer
```

## Inspect the Matchbox

Inspect the following services on the Matchbox VM:

```bash
sudo systemctl status isc-dhcp-server
sudo systemctl status dnsmasq-coreos
sudo systemctl status matchbox
```

## Clean up

In order to clean everything up: `make clean`
