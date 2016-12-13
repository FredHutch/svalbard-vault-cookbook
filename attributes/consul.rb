# Attributes for the consul server

# This is necessary to enable searches in the attributes
class AttributeSearch
  extend Chef::DSL::DataQuery
end

default['svalbard-vault']['consul']['version'] = '0.7.1'
default['svalbard-vault']['consul']['config'] = {
  'data_dir' => '/var/spool/consul/data',
  'dc' => 'e2',
  'bootstrap' => 'false'
}
servers = AttributeSearch.search(
  :node,
  'role:svalbard-consul-server',
  filter_result: { 'ip' => ['ipaddress'] }
)
servers = servers.collect { |e| e['ip'].to_s }
servers.delete('')

node.override['resolvconf']['nameserver'] = servers
