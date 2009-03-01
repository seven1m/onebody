class TechSupportEmailSettingNotGlobal < ActiveRecord::Migration
  def self.up
    Setting.find_all_by_section_and_name('Contact', 'Tech Support Email').each do |setting|
      setting.destroy
    end
    Setting.update_all
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, 'Cannot revert this migration.'
  end
end
