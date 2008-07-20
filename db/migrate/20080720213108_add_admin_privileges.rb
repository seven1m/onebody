class AddAdminPrivileges < ActiveRecord::Migration
  def self.up
    change_table :admins do |t|
      t.boolean :import_data, :default => false
      t.boolean :export_data, :default => false
      t.boolean :run_reports, :default => false
    end
  end

  def self.down
    change_table :admins do |t|
      t.remove :import_data
      t.remove :export_data
      t.remove :run_reports
    end
  end
end
