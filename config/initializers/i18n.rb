# http://stackoverflow.com/questions/8066901/rails-how-to-treat-locale-translation-missing-as-error-during-test#answer-9690327

if Rails.env.development? || Rails.env.test?

  # raises exception when there is a wrong/no i18n key
  module I18n
    def self.just_raise_that_exception(*args)
      raise "i18n #{args.first}"
    end
  end

  I18n.exception_handler = :just_raise_that_exception

end
