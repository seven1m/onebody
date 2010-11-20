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

  def name
    I18n.t('name',
      :scope   => ['admin.settings', section, read_attribute(:name)],
      :default => read_attribute(:name)
    )
  end

  def description
    I18n.t(
      'description',
      :scope   => ['admin.settings', section, read_attribute(:name)]
    )
  end

  def value
    v = read_attribute(:value)
    case self['format'] # self.format causes a NoMethodError outside the Rails env
      when 'boolean'
        ![0, '0', 'f'].include?(v)
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
        SETTINGS[0][section][name]
      else
        if Site.current
          if SETTINGS[Site.current.id].nil?
            Site.current.add_settings
            Setting.precache_settings(true)
          end
          if SETTINGS[Site.current.id][section]
            return false if section == 'features' and Site.current.respond_to?("#{name}_enabled?") and not Site.current.send("#{name}_enabled?")
            SETTINGS[Site.current.id][section][name] || default
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
      find_all_by_section_and_name(section, name).each { |s| s.destroy }
    end

    def set(site_id, section, name, value) # must be proper case section and name
      raise 'Must be proper case string' if name.is_a? Symbol
      if setting = find_by_site_id_and_section_and_name(site_id, section, name)
        setting.update_attributes! :value => value
      else
        raise "No setting found for #{section}/#{name}."
      end
      precache_settings(true)
    end

    def set_global(section, name, value); set(nil, section, name, value); end

    def precache_settings(fresh=false)
      return if SETTINGS.any? and not fresh
      return unless table_exists?
      Setting.all.each do |setting|
        site_id = setting.global? ? 0 : setting.site_id
        section = setting.section.downcase.gsub(/\s/, '_')
        name = setting.name.downcase.gsub(/\s/, '_')
        SETTINGS[site_id] ||= {}
        SETTINGS[site_id][section] ||= {}
        SETTINGS[site_id][section][name] = setting.value
      end
      SETTINGS['timestamp'] = Time.now unless SETTINGS.empty?
      SETTINGS
    end

    def get_hash_of_settings_in_db(site_id)
      Setting.connection.select_all("select md5(group_concat(section, name)) as hash from settings where site_id = #{site_id} order by section, name").first['hash']
    end

    def get_hash_of_settings_in_yaml(settings, global=false)
      collected = []
      each_setting_from_hash(settings, global) do |section_name, setting_name, setting|
        collected << [section_name, setting_name]
      end
      Digest::MD5.hexdigest(collected.join)
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

    def update_from_yaml(filename)
      settings = YAML::load(File.open(filename))
      # per site settings
      Site.find_all_by_active(true).each do |site|
        if get_hash_of_settings_in_db(site.id) != get_hash_of_settings_in_yaml(settings)
          Rails.logger.info("Reloading settings for site #{site.id}...")
          update_site_from_hash(site, settings)
        end
      end
      # globals
      if get_hash_of_settings_in_db(0) != get_hash_of_settings_in_yaml(settings, true)
        Rails.logger.info("Reloading global settings...")
        global_settings_in_db = Setting.find_all_by_site_id(nil)
        each_setting_from_hash(settings, true) do |section_name, setting_name, setting|
          unless global_settings_in_db.detect { |s| s.section == section_name and s.name == setting_name }
            Setting.create!(setting.merge(:section => section_name, :name => setting_name))
          end
        end
      end
    end

    def update_site_from_hash(site, settings)
      settings_in_db = Setting.find_all_by_site_id(site.id)
      each_setting_from_hash(settings, false) do |section_name, setting_name, setting|
        unless settings_in_db.detect { |s| s.section == section_name and s.name == setting_name }
          setting['site_id'] = site.id
          Setting.create!(setting.merge(:section => section_name, :name => setting_name))
        end
      end
    end

    def update_site(site)
      update_site_from_hash(site, YAML::load(File.open(SETTINGS_FILE)))
      Dir[PLUGIN_SETTINGS_FILES].each do |path|
        update_site_from_hash(site, YAML::load(File.open(path)))
      end
    end

    def update_all
      Setting.update_from_yaml(SETTINGS_FILE)
      Dir[PLUGIN_SETTINGS_FILES].each do |path|
        Setting.update_from_yaml(path)
      end
      Setting.precache_settings(true)
    end

    def update_site_from_params(id, params)
      Setting.find_all_by_site_id(id).each do |setting|
        next if setting.hidden?
        value = params[setting.id.to_s]
        if setting.format == 'list'
          value = value.to_s.split(/\n/)
        elsif value == ''
          value = nil
        end
        setting.update_attributes! :value => value
      end
      Setting.precache_settings(true)
    end

    def update_global_from_params(params)
      Setting.find_all_by_site_id_and_global(nil, true).each do |setting|
        next if setting.hidden?
        value = params[setting.id.to_s]
        if setting.format == 'list'
          value = value.to_s.split(/\n/)
        elsif value == ''
          value = nil
        end
        setting.update_attributes! :value => value
      end
      Setting.precache_settings(true)
    end
  end
end
