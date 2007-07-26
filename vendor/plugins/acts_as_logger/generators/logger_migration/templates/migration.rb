class CreateLogItems < ActiveRecord::Migration
  def self.up
    create_table :log_items do |t|
      t.column :model_name, :string, :limit => 50
      t.column :instance_id, :integer
      t.column :changes, :text
      t.column :deleted, :boolean, :default => false
      t.column :person_id, :integer
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :log_items
  end
end
