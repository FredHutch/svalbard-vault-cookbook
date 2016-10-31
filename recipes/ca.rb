#
# Cookbook Name:: svalbard-vault
# Recipe:: ca
#
# Copyright (c) 2016 The Authors, All Rights Reserved.
#
# Create a CA for svalbard certificates

root_dir = node['svalbard-vault']['root_dir']

ca_dirs = [
  root_dir,
  "#{root_dir}/ca",
  "#{root_dir}/ca/bin",
  "#{root_dir}/ca/etc",
  "#{root_dir}/ca/requests",
  "#{root_dir}/ca/certs"
]

ca_dirs.each do |d|
  directory d do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
    recursive true
  end
end

directory "#{root_dir}/ca/private" do
  owner 'root'
  group 'root'
  mode '0700'
  action :create
end

file "#{root_dir}/ca/index.txt" do
  content ''
  owner 'root'
  group 'root'
  mode '0644'
end

file "#{root_dir}/ca/serial" do
  content '1000'
  owner 'root'
  group 'root'
  mode '0644'
end

template "#{root_dir}/ca/openssl.conf" do
  source 'ca/openssl.conf.erb'
  variables('ssl_dir' => "#{root_dir}/ca")
  owner 'root'
  mode '0644'
end

template "#{root_dir}/ca/etc/openssl.conf.tmpl" do
  source 'ca/openssl.conf.tmpl.erb'
  variables('ssl_dir' => "#{root_dir}/ca")
  owner 'root'
  mode '0644'
end

template "#{root_dir}/ca/bin/request-cert.sh" do
  source 'ca/request-cert.sh.erb'
  variables('ssl_dir' => "#{root_dir}/ca")
  owner 'root'
  mode '0755'
end

ssl_config_file = "#{root_dir}/ca/openssl.conf"
ca_cert = "#{root_dir}/ca/svalbard-root-ca.pem"
ca_key = "#{root_dir}/ca/private/svalbard-root-ca.key"

bash 'generate ca certificate and key' do
  cwd "#{root_dir}/ca"
  code <<-EREH
    openssl req -config #{ssl_config_file} -newkey rsa:2048 -days 3650 -x509 \
    -nodes -out #{ca_cert} -keyout #{ca_key} \
    -subj "#{node['svalbard-vault']['ca']['subject']}"
    EREH
  not_if { ::File.exist?(ca_cert) || ::File.exist?(ca_key) }
end
