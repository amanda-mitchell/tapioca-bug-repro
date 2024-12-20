# Workaround for https://github.com/Shopify/tapioca/issues/442
Rails = OpenStruct.new(application: OpenStruct.new(config: {}))

# In a real Rails app, we'd have the autoloader spin
# everything up, but we can just do a direct require here.
require_relative '../example'
