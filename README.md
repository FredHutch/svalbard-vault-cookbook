# svalbard-vault

c.f. http://www.seedvault.no/

Configure hashicorp vault and consul back-end servers.

# Bootstrapping into chef

```
knife bootstrap \
-r 'role[cit-base]','role[scicomp-base]','role[svalbard-consul-server]' \
--bootstrap-vault-item svalbard-certs:root_cert \
--bootstrap-vault-item svalbard-certs:<hostname> \
-N <fqdn> <fqdn>
```


# Configuration

## Generate Private CA for Signing Certs

SSL certificates are required for encryption and authentication of
nodes/services in the Consul/Vault infrastructure.  For this application we'll
be creating a private CA and using that for signing host certificates.

This process is documented in many places- the most applicable reference is [here](http://russellsimpkins.blogspot.com/2015/10/consul-adding-tls-using-self-signed.html).

> Note that there is a custom OpenSSL config file that is necessary for
> generating these certificates- it has some attributes not present in the
> stock config file.

### Create root certificate and key

```
openssl req -config <configfile> -newkey rsa:2048 -days 3650 -x509 \
-nodes -out <cert> -keyout <key>
```

The key needs to be kept safe.

### Generate CSR for node

```
openssl req -config <configfile> -newkey rsa:1024 -nodes \
-out <node>.csr -keyout <node>.key
```

Note that the server certificate needs to have a hostname like
`nodename.datacenter.consul` where `nodename` is the hostname of the server and
`datacenter` is the Consul "datacenter" (or group) for the cluster.

### Sign CSR and Deliver

```
openssl ca -config <configfile> -batch -notext \
-in <node>.csr -out <node>.pem
```

Copy node certificate and key (`node.pem`, `node.key`) as well as the root
certificate to the node.

### Install Consul and Certs

Download and extract (unzip).  I'm creating a heirarchy like this:

```
/opt/hashicorp/consul
                    /bin
                    /etc
                    /etc/ssl
```

extract the `consul` binary to `.../bin` and move the certificates into
`.../etc/ssl`

### Configure

Install `config.json` into `..../etc`.  Configure ``systemd` to start the
consul service

# Bootstrapping Consul

When configured as a server (i.e. has Chef role `svalbard-console-server`),
Chef will deliver a file called `config.bootstrap.json` into `consul/etc/`.
This is the config file we'll use for the bootstrapping as it contains the
nodes in the cluster.

 1. Choose a bootstrap "master"
 1. Edit `config.bootstrap.json`, removing the line with `start_join`
 1. Start consul manually: `bin/consul agent -bootstrap-expect 3 -config-file
    etc/config.bootstrap.json`.  Adjust the value for `bootstrap-expect` to
    match the number of servers in the cluster.
 1. Log into one of the other consul servers and start using the bootstrap
    config: `bin/consul agent -config-file etc/config.bootstrap.json`
 1. You should see messages on the bootstrap master and this server indicating
    that the server has joined the cluster
 1. Repeat the last two steps on all of the other systems in the cluster

When all servers have completed the join to the cluster:

 1. Return the the bootstrap master and stop consul with ctrl-c
 1. Restart using `service consul-agent start`
 1. Verify startup with `consul members` and `consul monitor`

Repeat these steps for each of the other consul servers.  The servers will all
then be on equal footing and running in HA mode.
 

