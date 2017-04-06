TranslationIO.configure do |config|
  config.api_key        = ENV['TRANSLATION_IO_API_KEY']
  config.source_locale  = 'en'
  config.target_locales = ['af-ZA', 'da', 'nl-NL', 'fr', 'de', 'pt', 'ro', 'ru']
  config.disable_gettext = true
end
