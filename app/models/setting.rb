class Setting < ActiveRecord::Base
  serialize :value
  
  def value
    v = read_attribute(:value)
    format == 'boolean' ? ![0, '0'].include?(v) : v
  end
  
  def value?; value; end
  
  def self.load_settings
    find(:all).each do |setting|
      SETTINGS[setting.section.downcase.gsub(/\s/, '_')] ||= {}
      SETTINGS[setting.section.downcase][setting.name.downcase.gsub(/\s/, '_')] = setting.value
    end
  end
end
