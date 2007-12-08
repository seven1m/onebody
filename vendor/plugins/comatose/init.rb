require 'support/class_options'
require 'acts_as_versioned'
require 'redcloth' unless defined?(RedCloth)
require 'liquid' unless defined?(Liquid)

require 'comatose'
require 'text_filters'

require 'support/route_mapper'

# if defined? ActionController::Routing::RouteSet::Mapper
#   require 'support/route_mapper'
# else
#   require 'support/routes'
# end
