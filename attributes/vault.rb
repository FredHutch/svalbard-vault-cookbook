# Attributes for the consul server

# This is necessary to enable searches in the attributes
class AttributeSearch
  extend Chef::DSL::DataQuery
end

default['svalbard-vault']['vault'] = {
  'version' => '0.6.3'
}
