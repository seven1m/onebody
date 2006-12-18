class CreateUpdates < ActiveRecord::Migration
  def self.up
    create_table :updates do |t|
      t.column :person_id, :integer
      t.column :first_name, :string, :limit => 255
      t.column :last_name, :string, :limit => 255
      t.column :home_phone, :bigint
      t.column :mobile_phone, :bigint
      t.column :work_phone, :bigint
      t.column :fax, :bigint
      t.column :address1, :string, :limit => 255
      t.column :address2, :string, :limit => 255
      t.column :city, :string, :limit => 255
      t.column :state, :string, :limit => 2
      t.column :zip, :string, :limit => 10
      t.column :birthday, :datetime
      t.column :anniversary, :datetime
      t.column :created_at, :datetime
      t.column :complete, :boolean, :default => false
    end
  end

  def self.down
    drop_table :updates
  end
end
