class HideSiteUrlSetting < ActiveRecord::Migration
  def self.up
    Setting.find_all_by_section_and_name('URL', 'Site').each do |setting|
      setting.hidden = true
      setting.save!
    end
    Site.each { |s| s.update_url }
  end

  def self.down
    Setting.find_all_by_section_and_name('URL', 'Site').each do |setting|
      setting.hidden = false
      setting.save!
    end
  end
end
