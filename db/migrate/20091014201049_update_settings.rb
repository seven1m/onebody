class UpdateSettings < ActiveRecord::Migration
  def self.up
    actual = YAML::load(File.open(RAILS_ROOT + '/config/settings.yml'))
    Setting.all.each do |setting|
      # remove old ones
      if not actual.has_key?(setting.section) or not actual[setting.section].has_key?(setting.name)
        setting.destroy
      # remove duplicates
      elsif Setting.count('*', :conditions => ['site_id = ? and section = ? and name = ?', setting.site_id, setting.section, setting.name]) > 1
        setting.destroy
      # update description and hidden attributes
      else
        setting.description = actual[setting.section][setting.name]['description']
        setting.hidden      = actual[setting.section][setting.name]['hidden'] ? true : false
        setting.save
      end
    end
    Setting.delete_all "section = 'Services' and name = 'Analytics' and site_id is null" # changed from global to site-specific
  end

  def self.down
  end
end
