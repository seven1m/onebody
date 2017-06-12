# http://mentalized.net/journal/2009/08/10/find_missing_translations_in_your_rails_application/

namespace :i18n do
  def collect_keys(scope, translations)
    full_keys = []
    translations.to_a.each do |key, translations|
      new_scope = scope.dup << key
      if translations.is_a?(Hash)
        full_keys += collect_keys(new_scope, translations)
      else
        full_keys << new_scope.join('.')
      end
    end
    full_keys
  end

  desc 'Find and list translation keys that do not exist in all locales'
  task missing_keys: :environment do
    # Make sure we’ve loaded the translations
    I18n.backend.send(:init_translations)
    puts "#{I18n.available_locales.size} #{I18n.available_locales.size == 1 ? 'locale' : 'locales'} available: #{I18n.available_locales.to_sentence}"

    # Get all keys from all locales
    all_keys = I18n.backend.send(:translations).collect do |_check_locale, translations|
      collect_keys([], translations).sort
    end.flatten.uniq
    puts "#{all_keys.size} #{all_keys.size == 1 ? 'unique key' : 'unique keys'} found."

    missing_keys = {}
    all_keys.each do |key|
      I18n.available_locales.each do |locale|
        I18n.locale = locale
        begin
          result = I18n.translate(key, raise: true)
        rescue I18n::MissingInterpolationArgument
          # noop
        rescue I18n::MissingTranslationData
          if missing_keys[key]
            missing_keys[key] << locale
          else
            missing_keys[key] = [locale]
          end
        end
      end
    end

    puts "#{missing_keys.size} #{missing_keys.size == 1 ? 'key is missing' : 'keys are missing'} from one or more locales:"
    missing_keys.keys.sort.each do |key|
      puts "'#{key}': Missing from #{missing_keys[key].join(', ')}"
    end
  end

  desc 'Find and list translation keys found in the app but not in all of the locales'
  task missing_keys2: :environment do
    # Make sure we’ve loaded the translations
    I18n.backend.send(:init_translations)
    puts "#{I18n.available_locales.size} #{I18n.available_locales.size == 1 ? 'locale' : 'locales'} available: #{I18n.available_locales.to_sentence}"

    # Get all keys from all locales
    available_keys = I18n.backend.send(:translations).collect do |_check_locale, translations|
      collect_keys([], translations).sort
    end.flatten.uniq

    # Get all keys used in app
    Dir[Rails.root.join('app/**/*')].each do |path|
      missing = []
      next if File.directory?(path)
      File.read(path).scan(/\Wt\(['"](.+?)['"]/).map(&:first).each do |key|
        unless available_keys.include?(key)
          if (possible_match = available_keys.detect { |k| k[0...key.length] == key }) && possible_match =~ /\.one$|\.other$|\.are$|\.is$|^relationships\.names\./
            # pass
          else
            missing << key
          end
        end
      end
      next unless missing.any?
      puts path
      puts missing
      puts
    end
  end

  desc "Find and list translation keys that aren't properly inserted (possibly) in the ERB views"
  task misused_keys: :environment do
    # Get all keys used in app
    misused_keys = []
    Dir[Rails.root.join('app/views/**/*.erb')].each do |path|
      matches = []
      next if File.directory?(path)
      File.read(path).scan(/.{0,11}I18n\.t\(/).map(&:to_s).each do |match|
        unless match =~ /<%= I18n| => I18n|link_to I18n|[\[\(]I18n|\+\s?I18n|, I18n|submit(_tag)? I18n|rescue I18n| [\?:] I18n|_to_remote I18n|_function I18n|\.label I18n|#\{I18n/
          matches << match
        end
      end
      next unless matches.any?
      puts path
      puts matches
      puts
    end
  end

  desc 'Find and remove translation keys that are no longer in use'
  task unused_keys: :environment do
    require 'highline/import'
    require Rails.root.join('lib/i18n_scanner')

    # Make sure we’ve loaded the translations
    I18n.backend.send(:init_translations)
    puts "#{I18n.available_locales.size} #{I18n.available_locales.size == 1 ? 'locale' : 'locales'} available: #{I18n.available_locales.to_sentence}"

    # Get all keys from all locales
    available_keys = I18n.backend.send(:translations).collect do |check_locale, translations|
      next unless check_locale == :en # FIXME
      collect_keys([], translations).sort
    end.compact.flatten.map do |key|
      key.sub(/\.(one|other)$/, '')
    end.uniq

    available_keys.reject! do |key|
      key =~ /^activerecord|^time|^support|^relationships|^number|^errors|^date|^admin\.privileges|^admin\.settings/
    end

    # Get all keys used in app
    used_keys = I18nScanner.new.keys

    # loop thru keys not found in the app
    unused_keys = (available_keys - used_keys.uniq).sort
    kill = []
    puts format('%d unused keys', unused_keys.length)
    kill = unused_keys.each_with_object({}) do |key, hash|
      hash[key] = begin
                    I18n.t(key)
                  rescue
                    '???? could not retrieve translation value ????'
                  end
    end
    File.open('kill.yml', 'wb') { |f| YAML.dump(kill, f) }
  end
end
