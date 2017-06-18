class GeocoderJob < ActiveJob::Base
  queue_as :geocode

  class GeocodingError < StandardError; end

  SLEEP_MULTIPLIER = 3
  MAX_SLEEP_TIME = 12.hours
  MAX_FAILURE_COUNT = 2

  def perform(site, model_type, model_id)
    @delay = 1
    @error_count = 0
    ActiveRecord::Base.connection_pool.with_connection do
      Site.with_current(site) do
        klass = model_type.constantize
        klass.with_advisory_lock('geocode') do # only one at a time
          model = klass.find(model_id)
          geocode_model(model)
        end
      end
    end
    sleep @delay unless Rails.env.test? # delay next GeocoderJob as a simple rate limit
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
    @delay *= SLEEP_MULTIPLIER
    if @delay > MAX_SLEEP_TIME
      raise GeocodingError,
            'Over geocoder rate limit for #{model.class.name} #{model.id}. Giving up.'
    else
      Rails.logger.warn(
        "Over geocoder rate limit for #{model.class.name} #{model.id}. " \
          "Sleeping for #{@delay} second(s)"
      )
      sleep @delay
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
          "This is error number #{@error_count}. Sleeping for 5 seconds."
      )
      sleep 5
    end
  end
end
