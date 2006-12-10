class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table :groups do |t|
      t.column :name, :string, :limit => 100
      t.column :description, :text
      t.column :meets, :string, :limit => 100
      t.column :location, :string, :limit => 100
      t.column :directions, :text
      t.column :notes, :text
      t.column :category, :string, :limit => 50
      t.column :creator_id, :integer
      t.column :private, :boolean, :default => false
      t.column :address, :string, :limit => 255
      t.column :members_send, :boolean, :default => true
      t.column :link_code, :string, :limit => 10
      t.column :subscription, :boolean, :default => false
    end
  end

  def self.down
    drop_table :groups
  end
end
