require 'active_support/concern'

module Concerns
  module Geocode
    extend ActiveSupport::Concern

    included do
      attr_accessor :dont_geocode
      after_save :geocode_later, if: :should_geocode?
    end

    def geocode_later
      GeocoderJob.perform_later(site, self.class.name, id)
    end

    def geocode
      if blank_address?
        self.latitude = nil
        self.longitude = nil
      else
        results = Geocoder.search(geocoding_address)
        if (result = results.first)
          self.latitude = result.latitude
          self.longitude = result.longitude
        else
          self.latitude = nil
          self.longitude = nil
        end
      end
    end

    class_methods do
      def geocode_with(*attrs)
        define_method :geocoding_address do
          attrs.map { |attr| send(attr) }.reject(&:blank?).join(', ')
        end

        define_method :blank_address? do
          (attrs - [:address2]).any? { |attr| send(attr).blank? }
        end

        define_method :should_geocode? do
          return false if dont_geocode
          attrs.any? { |attr| saved_change_to_attribute?(attr) }
        end
      end
    end
  end
end
