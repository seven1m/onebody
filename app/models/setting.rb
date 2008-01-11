# == Schema Information
# Schema version: 89
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
#

class Setting < ActiveRecord::Base
  serialize :value
  
  def value
    v = read_attribute(:value)
    format == 'boolean' ? ![0, '0', 'f'].include?(v) : v
  end
  
  def value?; value; end
  
  def self.load_settings
    load_settings_from_array find(:all).map { |s| [s.section, s.name, s.value] }
    update_template_view_paths
  end
  
  def self.load_settings_from_array(settings)
    settings.each do |section, name, value, format|
      section_name = section.downcase.gsub(/\s/, '_')
      setting_name = name.downcase.gsub(/\s/, '_')
      SETTINGS[section_name] ||= {}
      SETTINGS[section_name][setting_name] = (format == 'list' ? YAML::load(value) : value)
    end
  end
  
  def self.update_template_view_paths
    if SETTINGS['appearance'] and SETTINGS['appearance']['theme']
      ActionController::Base.view_paths.delete_if { |p| p =~ /themes/ }
      ActionController::Base.view_paths.unshift File.join(RAILS_ROOT, 'themes', SETTINGS['appearance']['theme'])
    end
  end
end
