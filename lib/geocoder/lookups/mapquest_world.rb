require 'cgi'
require 'geocoder/lookups/mapquest'
require 'geocoder/results/mapquest'

module Geocoder::Lookup
  class MapquestWorld < Mapquest

    def name
      'Mapquest World'
    end

    private

    def query_url_params(query)
      params = {
        inFormat: 'json',
        json: { location: query.text }.to_json
      }
      if key = configuration.api_key
        params[:key] = CGI.unescape(key)
      end
      params.merge(super).reject { |k| k == :location }
    end

  end
end
