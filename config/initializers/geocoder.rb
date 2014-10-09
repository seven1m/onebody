require_relative Rails.root.join('lib/geocoder/lookups/mapquest_world')
require_relative Rails.root.join('lib/geocoder/results/mapquest_world')

Geocoder.configure(
  lookup: :mapquest_world,
  api_key: Rails.application.secrets.mapquest_api_key
)

module Geocoder::Lookup
  def street_services_with_mapquest_world
    street_services_without_mapquest_world + [:mapquest_world]
  end
  alias_method_chain :street_services, :mapquest_world
end
