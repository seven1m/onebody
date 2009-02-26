class RemoveEmailSettings < ActiveRecord::Migration
  def self.up
    Setting.delete_all("section = 'Email'")
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, 'Cannot revert this migration.'
  end
end
