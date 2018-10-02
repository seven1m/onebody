class GeocoderJob < ApplicationJob
  queue_as :geocode

  class GeocodingError < StandardError; end

  RATE_LIMIT = 1 # second
  MAX_FAILURE_COUNT = 2

  def perform(site, model_type, model_id)
    @model_type = model_type
    @error_count = 0
    ActiveRecord::Base.connection_pool.with_connection do
      Site.with_current(site) do
        klass.with_advisory_lock('geocode') do # only one at a time
          model = klass.find(model_id)
          geocode_model(model)
          sleep RATE_LIMIT unless Rails.env.test? # delay next GeocoderJob as a simple rate limit
        end
      end
    end
  end

  def klass
    @model_type.constantize
  end

  def geocode_model(model)
    model.geocode
  rescue Geocoder::OverQueryLimitError
    over_query_limit_error(model)
    retry
  rescue Geocoder::Error, Timeout::Error => e
    general_error(model, e.message)
    retry
  else
    model.dont_geocode = true
    model.save(validate: false)
  end

  def over_query_limit_error(model)
    Rails.logger.warn(
      "Over geocoder rate limit for #{model.class.name} #{model.id}. " \
        "Sleeping for #{RATE_LIMIT} second(s)"
    )
    klass.with_advisory_lock('geocode') do
      sleep RATE_LIMIT
    end
  end

  def general_error(model, message)
    @error_count += 1
    if @error_count > MAX_FAILURE_COUNT
      raise GeocodingError,
            "Error geocoding for #{model.class.name} #{model.id}: #{message}. " \
            "This is error number #{@error_count}. Giving up."
    else
      Rails.logger.warn(
        "Error geocoding for #{model.class.name} #{model.id}: #{message}. " \
        "This is error number #{@error_count}. Sleeping..."
      )
      klass.with_advisory_lock('geocode') do
        sleep RATE_LIMIT
      end
    end
  end
end
