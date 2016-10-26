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

consul_dirs = [
  "#{node['svalbard-vault']['root_dir']}/consul",
  "#{node['svalbard-vault']['root_dir']}/consul/etc",
  "#{node['svalbard-vault']['root_dir']}/consul/etc/ssl",
  "#{node['svalbard-vault']['root_dir']}/consul/bin"
]

consul_dirs.each do |d|
  directory d do
    owner 'root'
    group 'root'
    mode 0755
    recursive true
  end
end

download_url = 'https://releases.hashicorp.com/consul/'\
  "#{node['svalbard-vault']['consul']['version']}/"\
  "consul_#{node['svalbard-vault']['consul']['version']}_"\
  "#{node['os']}_amd64.zip"

bash 'download and deploy consul' do
  cwd node['svalbard-vault']['root_dir']
  code <<-EREH
  wget -O /tmp/consul.zip #{download_url} && \
  unzip /tmp/consul.zip -d #{node['svalbard-vault']['root_dir']}/consul/bin
  EREH
  not_if do
    ::File.exist?("#{node['svalbard-vault']['root_dir']}/consul/bin/consul")
  end
end

# Load hosts ssl keys from vault and install for consul

ssl_dir = "#{node['svalbard-vault']['root_dir']}/consul/etc/ssl"
my_cert = chef_vault_item('svalbard-certs', node['hostname'])
root_cert = chef_vault_item('svalbard-certs', 'root_cert')

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
  content my_cert['certificate']
  owner 'root'
  group 'root'
  mode 0644
end

file "#{ssl_dir}/#{node['hostname']}.key" do
  content my_cert['key']
  owner 'root'
  group 'root'
  mode 0644
end

template "#{node['svalbard-vault']['root_dir']}/consul/etc/config.json" do
  source 'consul-config.json.erb'
  variables(
    'ca_file'    => "#{ssl_dir}/svalbard-root-ca.pem",
    'key_file'   => "#{ssl_dir}/#{node['hostname']}.key",
    'cert_file'  => "#{ssl_dir}/#{node['hostname']}.pem",
    'bind_addr'  => node['ipaddress'],
    'data_dir'   => node['svalbard-vault']['consul']['config']['data_dir'],
    'datacenter' => node['svalbard-vault']['consul']['config']['dc']
  )
end

bash 'enable agent' do
  code 'systemctl enable consul-agent.service'
  action :nothing
end

template '/lib/systemd/system/consul-agent.service' do
  source 'consul-agent.service.erb'
  owner 'root'
  group 'root'
  mode 0644
  variables(
    'bin_consul' => "#{node['svalbard-vault']['root_dir']}/consul/bin/consul",
    'etc_consul' => "#{node['svalbard-vault']['root_dir']}/consul/etc"
  )
  notifies :run, 'bash[enable agent]'
end
