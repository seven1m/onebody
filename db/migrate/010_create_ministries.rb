class CreateMinistries < ActiveRecord::Migration
  def self.up
    create_table :ministries do |t|
      t.column :admin_id, :integer
      t.column :name, :string, :limit => 100
      t.column :description, :text
    end
  end

  def self.down
    drop_table :ministries
  end
end
