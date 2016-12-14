#
# Cookbook Name:: svalbard-vault
# Recipe:: vault
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

#
# Cookbook Name:: svalbard-vault
# Recipe:: consul
#
# Copyright (c) 2016 The Authors, All Rights Reserved.
#

include_recipe 'chef-vault'

directory node['svalbard-vault']['root_dir'] do
  owner 'root'
  group 'root'
  mode 0755
  recursive true
end

user 'vault' do
  comment 'Hashicorp Vault Service Account'
  home "#{node['svalbard-vault']['root_dir']}/vault"
  shell '/bin/bash'
end

vault_dirs = [
  "#{node['svalbard-vault']['root_dir']}/vault",
  "#{node['svalbard-vault']['root_dir']}/vault/etc",
  "#{node['svalbard-vault']['root_dir']}/vault/etc/ssl",
  "#{node['svalbard-vault']['root_dir']}/vault/bin"
]

vault_dirs.each do |d|
  directory d do
    owner 'root'
    group 'root'
    mode 0755
    recursive true
  end
end

download_url = 'https://releases.hashicorp.com/vault/'\
  "#{node['svalbard-vault']['vault']['version']}/"\
  "vault_#{node['svalbard-vault']['vault']['version']}_"\
  "#{node['os']}_amd64.zip"

bash 'download and deploy vault' do
  cwd node['svalbard-vault']['root_dir']
  code <<-EREH
  rm -f /tmp/vault.zip \
    #{node['svalbard-vault']['root_dir']}/vault/bin/vault && \
  wget -O /tmp/vault.zip #{download_url} && \
  unzip /tmp/vault.zip -d #{node['svalbard-vault']['root_dir']}/vault/bin
  EREH
  not_if do
    ::File.exist?("#{node['svalbard-vault']['root_dir']}/vault/bin/vault")
  end
end

# Load hosts ssl keys from vault and install for consul

ssl_dir     = "#{node['svalbard-vault']['root_dir']}/vault/etc/ssl"
consul_cert = chef_vault_item('svalbard-certs', node['hostname'])
root_cert   = chef_vault_item('svalbard-certs', 'root_cert')
secrets     = chef_vault_item('svalbard-certs', 'secrets')
wildcard    = chef_vault_item('svalbard-certs', 'wildcard')

file "#{ssl_dir}/svalbard-root-ca.pem" do
  content root_cert['certificate']
  owner 'root'
  group 'root'
  mode 0644
end

trusted_certificate 'svalbard' do
  action :create
  content root_cert['certificate']
end

file "#{ssl_dir}/#{node['hostname']}.pem" do
  content consul_cert['certificate']
  owner 'root'
  group 'root'
  mode 0644
end

file "#{ssl_dir}/#{node['hostname']}.key" do
  content consul_cert['key']
  owner 'root'
  group 'root'
  mode 0644
end

file "#{ssl_dir}/wildcard.key" do
  content wildcard['key']
  owner 'root'
  group 'root'
  mode 0644
end

file "#{ssl_dir}/wildcard.pem" do
  content wildcard['certificate']
  owner 'root'
  group 'root'
  mode 0644
end

acl_master_token = secrets['acl_master_token']

backend_config = {
  'type'             => 'consul',
  'service'          => 'svalbard-vault',
  'address'          => "#{node['ipaddress']}:8443",
  'scheme'           => 'https',
  'path'             => 'vault',
  'tls_ca_file'      => "#{ssl_dir}/svalbard-root-ca.pem",
  'tls_key_file'     => "#{ssl_dir}/#{node['hostname']}.key",
  'tls_cert_file'    => "#{ssl_dir}/#{node['hostname']}.pem",
  'acl_master_token' => acl_master_token
}

listener_config = {
  'type'          => 'tcp',
  'address'       => "#{node['ipaddress']}:8443",
  'tls_disable'   => '0',
  'tls_key_file'  => "#{ssl_dir}/wildcard.key",
  'tls_cert_file' => "#{ssl_dir}/wildcard.pem"
}

template_variables = {
  "listener_config" => listener_config,
  "backend_config" => backend_config
}

template "#{node['svalbard-vault']['root_dir']}/vault/etc/config.hcl" do
  source 'vault/config.hcl.erb'
  variables(template_variables)
end

bash 'enable vault server' do
  code 'systemctl enable vault-server.service'
  action :nothing
end

template '/lib/systemd/system/vault-server.service' do
  source 'vault/vault-server.service.erb'
  owner 'root'
  group 'root'
  mode 0644
  variables(
    'bin_vault' => "#{node['svalbard-vault']['root_dir']}/vault/bin/vault",
    'etc_vault' => "#{node['svalbard-vault']['root_dir']}/"\
      'vault/etc/config.json'
  )
  notifies :run, 'bash[enable vault server]'
end
