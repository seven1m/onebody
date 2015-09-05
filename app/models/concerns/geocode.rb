require 'active_support/concern'

module Concerns
  module Geocode
    extend ActiveSupport::Concern

    included do
      attr_accessor :dont_geocode
      after_validation :geocode, if: :should_geocode?
      after_validation :clear_lat_lon, if: :blank_address?
    end

    module ClassMethods
      def geocode_with(location)
        proc = method(:process_geocode_result).to_proc
        geocoded_by location, &proc
      end

      def process_geocode_result(model, results=nil)
        if (geocoding_data = results.first) && geocoding_data.try(:precision) != 'APPROXIMATE'
          model.latitude = geocoding_data.latitude
          model.longitude = geocoding_data.longitude
        else
          model.latitude = nil
          model.longitude = nil
        end
      end
    end

    def clear_lat_lon
      self.latitude = nil
      self.longitude = nil
    end

    def should_geocode?
      return false if dont_geocode
      changes = address1_changed? || address2_changed? || city_changed? || state_changed? || zip_changed?
      changes && !blank_address?
    end

    def blank_address?
      address1.blank? || city.blank? || state.blank?
    end
  end
end
