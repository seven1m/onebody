class RemoveOldAdminPrivileges < ActiveRecord::Migration
  def self.up
    change_table :admins do |t|
      %w(manage_music manage_log manage_shares manage_prayer_signups run_reports).each do |col|
        t.remove(col) rescue nil
      end
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
