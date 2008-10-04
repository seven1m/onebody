class AddTimeZoneSupport < ActiveRecord::Migration
  def self.up
    Setting.update_all # add new System Time Zone setting from settings.yml
  end

  def self.down
  end
end
