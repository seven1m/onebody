class CreateJobs < ActiveRecord::Migration
  def self.up
    create_table :jobs do |t|
      t.integer :site_id
      t.string :command, :limit => 255
      t.timestamps
    end
  end

  def self.down
    drop_table :jobs
  end
end
