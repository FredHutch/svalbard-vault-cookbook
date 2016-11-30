default['svalbard-vault']['consul']['version'] = '0.7.1'
default['svalbard-vault']['consul']['config'] = {
  'data_dir' => '/var/spool/consul/data',
  'dc' => 'e2',
  'bootstrap' => 'false'
}

node.override['resolvconf']['nameservers'] = ['140.107.117.11']
