#!/bin/bash

while getopts "d:x:" opt
do
	case "$opt" in
		d)
			datacenter=$OPTARG
			;;
		x)
			hostname=$OPTARG
			;;
	esac
done

if [ -z ${datacenter+x} ] || [ -z ${hostname+x}  ]
then
	echo "hostname or datacenter not specified."
	exit 1
fi

echo "Making certificate for $hostname in $datacenter"
dn=$(dnsdomainname)
dn=fhcrc.org

hostname=$(basename $hostname $dn)
ip=$(dig +short $hostname.$dn)

cert_host_name=${hostname}.${datacenter}.consul

# Generate OpenSSL configuration with alternate names usable
# by this certificate
ssl_config=$(tempfile)
cp etc/openssl.conf.tmpl ${ssl_config}

cat >> ${ssl_config} <<EREH
[alt_names]
DNS.1 = ${hostname}
DNS.2 = ${hostname}.${dn}
DNS.3 = ${ip}
EREH

# Generate CSR

openssl req -config ${ssl_config} \
  -subj "/C=US/ST=Washington/L=Seattle/O=Fred Hutchinson CRC/OU=Scientific Computing/CN=${cert_host_name}/emailAddress=scicomp@fhcrc.org" \
  -newkey rsa:1024 -nodes \
  -out requests/${cert_host_name}.csr -keyout certs/${cert_host_name}.key

openssl ca -config  ${ssl_config} \
  -batch -notext \
  -in requests/${cert_host_name}.csr \
  -out certs/${cert_host_name}.pem

# Generate json for upload to vault

json_crt=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' certs/${cert_host_name}.pem)
json_key=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' certs/${cert_host_name}.key)

cat > certs/${cert_host_name}.json <<EREH
{
    "id": "vault",
    "key": "${json_key}",
    "certificate": "${json_crt}"
}
EREH

rm ${ssl_config}
