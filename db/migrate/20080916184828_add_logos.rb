class AddLogos < ActiveRecord::Migration
  def self.up
    Setting.update_all
  end

  def self.down
  end
end
