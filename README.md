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
