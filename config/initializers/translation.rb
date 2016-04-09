TranslationIO.configure do |config|
  config.api_key        = '156df59d0e0449d48f38077536f8acce'
  config.source_locale  = 'en'
  config.target_locales = ['af-ZA', 'da', 'nl-NL', 'fr', 'de', 'pt', 'ro', 'ru']

  # Uncomment this if you don't want to use gettext
  config.disable_gettext = true

  # Uncomment this if you already use gettext or fast_gettext
  # config.locales_path = File.join('path', 'to', 'gettext_locale')

  # Find other useful usage information here:
  # https://github.com/aurels/translation-gem/blob/master/README.md
end
