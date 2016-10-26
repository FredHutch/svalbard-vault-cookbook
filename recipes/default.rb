#
# Cookbook Name:: svalbard-vault
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

include_recipe 'consul-cluster::default'

poise_service_user node['hashicorp-vault']['service_user'] do
  group node['hashicorp-vault']['service_group']
end

directory File.dirname(node['svalbard-vault']['tls']['ssl_key']['path']) do
  recursive true
  owner node['hashicorp-vault']['service_user']
  group node['hashicorp-vault']['service_group']
end

directory File.dirname(node['svalbard-vault']['tls']['ssl_cert']['path']) do
  recursive true
  owner node['hashicorp-vault']['service_user']
  group node['hashicorp-vault']['service_group']
end

ssl_certificate node['hashicorp-vault']['service_name'] do
  owner node['hashicorp-vault']['service_user']
  group node['hashicorp-vault']['service_group']
  namespace node['svalbard-vault']['tls']
  notifies :reload, "vault_service[#{name}]", :delayed
end

node.default['hashicorp-vault']['config']['backend_type'] = 'consul'
#node.default['hashicorp-vault']['config']['bag_item'] = 'consul'
node.default['hashicorp-vault']['config']['tls_disable'] = false
include_recipe 'hashicorp-vault::default'
