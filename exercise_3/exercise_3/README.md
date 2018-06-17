# Exercise 3

## Starting Matchbox

```bash
make pxe_server
```

`sudo docker exec -ti etcd etcdctl -u root:rootpw watch /nodes/kmaster-fluffy-unicorn-az01-001/deploy`

TODO write docs DOCS

TODO verify write

## SSH into the new hosts

In order to ssh into the newly provisioned hosts you need to ssh into the `pxe_server` with `vagrant ssh pxe_server` now you can ssh into the other machines:

```bash
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i insecure_private_key core@192.168.1.2 cat /etc/my_type
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i insecure_private_key core@192.168.1.3
```

Verify that the installer run successfully:

```bash
journalctl -fu installer
```
