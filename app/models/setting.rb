class Setting < ActiveRecord::Base
  GLOBAL_SETTINGS = [
    'Contact.Tech Support Email', 'Contact.Bug Notification Email',
    'Services.Yahoo',
    'Features.Multisite', 'Features.SSL', 'Features.Edit Legacy Ids', 'Features.Reporting'
  ]

  SETTINGS_FILE = Rails.root.join("config/settings.yml")
  PLUGIN_SETTINGS_FILES = Rails.root.join("plugins/**/config/settings.yml")

  serialize :value
  belongs_to :site

  cattr_accessor :current

  def value
    v = read_attribute(:value)
    case self['format'] # self.format causes a NoMethodError outside the Rails env
      when 'boolean'
        ![0, '0', 'f', false].include?(v)
      when 'list'
        v.is_a?(Array) ? v : v.to_s.split(/\n/)
      else
        v
    end
  end

  def value?; value; end

  class << self
    def get(section, name, default=nil)
      precache_settings unless SETTINGS.any?
      return nil unless SETTINGS.any?
      section, name = section.to_s, name.to_s
      if global?(section, name)
        SETTINGS[0][section][name].try(:value)
      else
        if Site.current
          if SETTINGS[Site.current.id].nil?
            Site.current.add_settings
            Setting.precache_settings(true)
          end
          if SETTINGS[Site.current.id][section]
            return false if section == 'features' and Site.current.respond_to?("#{name}_enabled?") and not Site.current.send("#{name}_enabled?")
            SETTINGS[Site.current.id][section][name].try(:value) || default
          else
            default
          end
        else
          raise "Site.current is not set so Setting.get(:#{section}, :#{name}) failed."
        end
      end
    end

    def global?(section, name)
      Setting::GLOBAL_SETTINGS.map { |s| s.split('.').map { |p| p.underscore.gsub(' ', '_') } }.include? [section, name]
    end

    def delete(section, name) # must be proper case section and name
      raise 'Must be proper case string' if name.is_a? Symbol
      where(section: section, name: name).each { |s| s.destroy }
    end

    def set(*args)
      if args.length == 3
        set_current(*args)
      else
        set_any(*args)
      end
    end

    def set_current(section, name, value)
      set_any(Site.current.id, section, name, value)
    end

    def set_any(site_id, section, name, value)
      if section.is_a?(Symbol) and name.is_a?(Symbol)
        setting = SETTINGS[site_id][section.to_s][name.to_s]
        section = setting.section
        name = setting.name
      end
      if setting = where(site_id: site_id, section: section, name: name).first
        setting.update_attributes! value: value
      else
        raise "No setting found for #{section}/#{name}."
      end
      precache_settings(true)
    end

    def set_global(section, name, value); set(nil, section, name, value); end

    def reload_if_stale
      precache_settings(true) if cache_stale?
    end

    def cache_stale?
      Site.current.settings_changed_at and \
      SETTINGS['timestamp'] < Site.current.settings_changed_at
    end

    def precache_settings(fresh=false)
      return if SETTINGS.any? and not fresh
      return unless table_exists?
      Setting.all.each do |setting|
        site_id = setting.global? ? 0 : setting.site_id
        section = setting.read_attribute(:section).downcase.gsub(/\s/, '_')
        name = setting.read_attribute(:name).downcase.gsub(/\s/, '_')
        SETTINGS[site_id] ||= {}
        SETTINGS[site_id][section] ||= {}
        SETTINGS[site_id][section][name] = setting
      end
      SETTINGS['timestamp'] = Time.now unless SETTINGS.empty?
      SETTINGS
    end

    def get_hash_of_settings_in_db(site_id=nil)
      Setting.connection.execute("set group_concat_max_len = 2048")
      Setting.connection.select_all("select md5(lower(group_concat(section, name order by lower(section), lower(name)))) as hash from settings where #{site_id ? ('site_id = ' + site_id.to_s) : 'global = 1'}").first['hash']
    end

    def get_hash_of_settings_in_yaml(settings, global=false)
      collected = []
      settings.keys.sort_by(&:downcase).each do |section_name|
        settings[section_name].keys.sort_by(&:downcase).each do |setting_name|
          if !!settings[section_name][setting_name]['global'] == global
            collected << (section_name+setting_name).downcase
          end
        end
      end
      Digest::MD5.hexdigest(collected.join(','))
    end

    def each_setting_from_hash(settings, global=false)
      settings.each do |section_name, section|
        section.each do |setting_name, setting|
          if !!setting['global'] == global
            yield(section_name, setting_name, setting)
          end
        end
      end
    end

    def update_all
      settings = load_settings_hash
      # per site settings
      Site.where(active: true).each do |site|
        if get_hash_of_settings_in_db(site.id) != get_hash_of_settings_in_yaml(settings)
          Rails.logger.info("Reloading settings for site #{site.id}...")
          update_site_from_hash(site, settings)
        end
      end
      # globals
      if get_hash_of_settings_in_db != get_hash_of_settings_in_yaml(settings, true)
        Rails.logger.info("Reloading global settings...")
        global_settings_in_db = Setting.where(global: true).to_a
        each_setting_from_hash(settings, true) do |section_name, setting_name, setting|
          unless global_settings_in_db.detect { |s| s.section == section_name and s.name == setting_name }
            global_settings_in_db << Setting.create!(setting.merge(section: section_name, name: setting_name))
          end
        end
        global_settings_in_db.each do |setting|
          unless settings[setting.section] && settings[setting.section][setting.name]
            setting.destroy
          end
        end
      end
      Setting.precache_settings(true)
    end

    def update_site_from_hash(site, settings)
      settings_in_db = Setting.where(site_id: site.id).to_a
      each_setting_from_hash(settings, false) do |section_name, setting_name, setting|
        unless settings_in_db.detect { |s| s.section == section_name and s.name == setting_name }
          setting['site_id'] = site.id
          settings_in_db << Setting.create!(setting.merge(section: section_name, name: setting_name))
        end
      end
      settings_in_db.each do |setting|
        unless settings[setting.section] && settings[setting.section][setting.name]
          setting.destroy
        end
      end
    end

    def update_site(site)
      update_site_from_hash(site, load_settings_hash)
    end

    def load_settings_hash
      YAML::load(File.open(SETTINGS_FILE)).tap do |settings|
        Dir[PLUGIN_SETTINGS_FILES].each do |path|
          YAML::load(File.open(path)).each do |n, s|
            settings[n].merge!(s)
          end
        end
      end
    end

    def update_site_from_params(id, params)
      Setting.where(site_id: id).each do |setting|
        next if setting.hidden?
        value = params[setting.id.to_s]
        if setting.format == 'list'
          value = value.to_s.split(/\n/)
        elsif value == ''
          value = nil
        end
        setting.update_attributes! value: value
      end
      Setting.precache_settings(true)
    end

    def update_global_from_params(params)
      Setting.where(site_id: nil, global: true).each do |setting|
        next if setting.hidden?
        value = params[setting.id.to_s]
        if setting.format == 'list'
          value = value.to_s.split(/\n/)
        elsif value == ''
          value = nil
        end
        setting.update_attributes! value: value
      end
      Setting.precache_settings(true)
    end
  end
end
