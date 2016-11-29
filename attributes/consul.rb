default['svalbard-vault']['consul']['version'] = '0.7.1'
default['svalbard-vault']['consul']['config'] = {
  'data_dir' => '/var/spool/consul/data',
  'dc' => 'e2',
  'bootstrap' => 'false'
}
