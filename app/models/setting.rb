# == Schema Information
# Schema version: 4
#
# Table name: settings
#
#  id          :integer       not null, primary key
#  section     :string(100)   
#  name        :string(100)   
#  format      :string(20)    
#  value       :string(255)   
#  description :string(500)   
#  hidden      :boolean       
#  created_at  :datetime      
#  updated_at  :datetime      
#  site_id     :integer       
#  global      :boolean       
#

class Setting < ActiveRecord::Base
  GLOBAL_SETTINGS = [
    'Email.Host', 'Email.Domain',
    'Contact.Tech Support Email', 'Contact.Tech Support Contact', 'Contact.Bug Notification Email',
    'Services.Yahoo', 'Services.Amazon', 'Services.Analytics',
    'Features.Multisite', 'Features.SSL'
  ]
  
  serialize :value
  belongs_to :site
  
  cattr_accessor :current
  
  def value
    v = read_attribute(:value)
    format == 'boolean' ? ![0, '0', 'f'].include?(v) : v
  end
  
  def value?; value; end
  
  class << self
    @@settings = nil
    
    def get(section, name)
      precache_settings unless @@settings
      return nil unless @@settings
      section, name = section.to_s, name.to_s
      if global?(section, name)
        @@settings[0][section][name]
      else
        if Site.current
          if @@settings[Site.current.id].nil?
            Site.current.duplicate_settings
            Setting.precache_settings(true)
          end
          if @@settings[Site.current.id][section]
            @@settings[Site.current.id][section][name]
          else
            nil
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
      return if @@settings and not fresh
      return unless table_exists?
      @@settings = {}
      find(:all).each do |setting|
        site_id = setting.global? ? 0 : setting.site_id
        section = setting.section.downcase.gsub(/\s/, '_')
        name = setting.name.downcase.gsub(/\s/, '_')
        @@settings[site_id] ||= {}
        @@settings[site_id][section] ||= {}
        @@settings[site_id][section][name] = setting.value
      end
      @@settings
    end
    
    def update_from_yaml(filename)
      settings = YAML::load(File.open(filename))
      Site.find(:all).each do |site|
        settings.each do |fixture, values|
          unless Setting.find_by_site_id_and_section_and_name(site.id, values['section'], values['name'])
            values.update 'site_id' => site.id
            Setting.create(values)
          end
        end
      end
    end
  end
end
