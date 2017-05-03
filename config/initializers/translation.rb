TranslationIO.configure do |config|
  config.api_key        = ENV['TRANSLATION_IO_API_KEY']
  config.source_locale  = 'en'
  config.target_locales = ['af-ZA', 'da', 'de', 'es-MX', 'fr', 'nl-NL', 'pt', 'ro', 'ru']
  config.disable_gettext = true
end
