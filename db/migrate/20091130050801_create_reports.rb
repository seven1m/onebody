class CreateReports < ActiveRecord::Migration
  def self.up
    create_table :reports do |t|
      t.integer :site_id
      t.string :name, :limit => 255
      t.text :definition
      t.boolean :restricted, :default => true
      t.integer :created_by_id
      t.integer :run_count, :default => 0
      t.datetime :last_run_at
      t.integer :last_run_by_id
      t.timestamps
    end
    create_table :admins_reports, :id => false do |t|
      t.integer :admin_id
      t.integer :report_id
    end
  end

  def self.down
    drop_table :reports
    drop_table :admins_reports
  end
end
