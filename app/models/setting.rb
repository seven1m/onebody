class Setting < ActiveRecord::Base
  serialize :value
  
  def value
    v = read_attribute(:value)
    format == 'boolean' ? ![0, '0'].include?(v) : v
  end
  
  def value?; value; end
  
  def self.load_settings
    load_settings_from_array find(:all).map { |s| [s.section, s.name, s.value] }
    update_template_view_paths
  end
  
  def self.load_settings_from_array(settings)
    settings.each do |section, name, value|
      section_name = section.downcase.gsub(/\s/, '_')
      setting_name = name.downcase.gsub(/\s/, '_')
      SETTINGS[section_name] ||= {}
      SETTINGS[section_name][setting_name] = value
    end
  end
  
  def self.update_template_view_paths
    if SETTINGS['appearance'] and SETTINGS['appearance']['theme']
      ActionController::Base.view_paths.delete_if { |p| p =~ /themes/ }
      root = defined?(APP_ROOT) ? APP_ROOT : RAILS_ROOT
      ActionController::Base.view_paths.unshift File.join(root, 'themes', SETTINGS['appearance']['theme'])
    end
  end
end
