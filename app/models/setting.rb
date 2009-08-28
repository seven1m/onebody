# == Schema Information
#
# Table name: settings
#
#  id          :integer       not null, primary key
#  section     :string(100)   
#  name        :string(100)   
#  format      :string(20)    
#  value       :string(500)   
#  description :string(500)   
#  hidden      :boolean       
#  created_at  :datetime      
#  updated_at  :datetime      
#  site_id     :integer       
#  global      :boolean       
#

class Setting < ActiveRecord::Base
  GLOBAL_SETTINGS = [
    'Email.Host', 'Email.Domain', 'Email.Authentication Required',
    'Contact.Tech Support Email', 'Contact.Tech Support Contact', 'Contact.Bug Notification Email',
    'Services.Yahoo', 'Services.Amazon', 'Services.Analytics',
    'Features.Multisite', 'Features.SSL', 'Features.Edit Legacy Ids'
  ]
  
  SETTINGS_FILE = File.join(RAILS_ROOT, "config/settings.yml")
  
  serialize :value
  belongs_to :site
  
  cattr_accessor :current
  
  def value
    v = read_attribute(:value)
    self['format'] == 'boolean' ? ![0, '0', 'f'].include?(v) : v # self.format causes a NoMethodError outside the Rails env
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
      find(:all).each do |setting|
        site_id = setting.global? ? 0 : setting.site_id
        section = setting.section.downcase.gsub(/\s/, '_')
        name = setting.name.downcase.gsub(/\s/, '_')
        SETTINGS[site_id] ||= {}
        SETTINGS[site_id][section] ||= {}
        SETTINGS[site_id][section][name] = setting.value
      end
      SETTINGS
    end
    
    def settings_in_db
      @settings_in_db ||= Setting.all
    end
    
    def update_from_yaml(filename)
      settings = YAML::load(File.open(filename))
      # per site settings
      Site.find(:all).each do |site|
        update_site_from_hash(site, settings)
      end
      # globals
      settings.each do |section_name, section|
        section.each do |setting_name, setting|
          next unless setting['global']
          unless settings_in_db.detect { |s| s.site_id == nil and s.section == section_name and s.name == setting_name }
            Setting.create!(setting.merge(:section => section_name, :name => setting_name))
          end
        end
      end
    end
    
    def update_site_from_hash(site, settings)
      settings.each do |section_name, section|
        section.each do |setting_name, setting|
          next if setting['global']
          unless settings_in_db.detect { |s| s.site_id == site.id and s.section == section_name and s.name == setting_name }
            setting['site_id'] = site.id
            Setting.create!(setting.merge(:section => section_name, :name => setting_name))
          end
        end
      end
    end
    
    def update_site(site)
      update_site_from_hash(site, YAML::load(File.open(SETTINGS_FILE)))
    end
    
    def update_all
      Setting.update_from_yaml(SETTINGS_FILE)
    end
    
    def update_site_from_params(id, params)
      Setting.find_all_by_site_id(id).each do |setting|
        next if setting.hidden?
        value = params[setting.id.to_s]
        value = value.split(/\n/) if value and setting.format == 'list'
        value = value == '' ? nil : value
        setting.update_attributes! :value => value
      end
      Setting.precache_settings(true)
    end
    
    def update_global_from_params(params)
      Setting.find_all_by_site_id_and_global(nil, true).each do |setting|
        next if setting.hidden?
        value = params[setting.id.to_s]
        value = value.split(/\n/) if value and setting.format == 'list'
        value = value == '' ? nil : value
        setting.update_attributes! :value => value
      end
      Setting.precache_settings(true)
    end
  end
end
