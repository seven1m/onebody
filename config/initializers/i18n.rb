module I18n
  class JustRaiseExceptionHandler < ExceptionHandler
    def call(exception, locale, key, options)
      if exception.is_a?(MissingTranslation)
        raise exception.to_exception
      else
        super
      end
    end
  end
end

if Rails.env.development? || Rails.env.test?
  I18n.exception_handler = I18n::JustRaiseExceptionHandler.new
end
