class UpdateSettings < ActiveRecord::Migration
  def self.up
    Setting.find_all_by_section_and_name('Features', 'Standalone Use').each { |s| s.destroy }
  end

  def self.down
    Setting.update_all
  end
end
