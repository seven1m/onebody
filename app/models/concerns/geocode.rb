require 'active_support/concern'

module Concerns
  module Geocode
    extend ActiveSupport::Concern

    module ClassMethods
      def geocode_with(location)
        proc = method(:process_geocode_result).to_proc
        geocoded_by location, &proc
        after_validation :geocode
      end

      def process_geocode_result(model, results=nil)
        if (geocoding_data = results.first) && geocoding_data.try(:precision) != 'APPROXIMATE'
          model.longitude = geocoding_data.longitude
          model.latitude = geocoding_data.latitude
        else
          model.longitude = nil
          model.latitude = nil
        end
      end
    end
  end
end
