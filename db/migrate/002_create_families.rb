class CreateFamilies < ActiveRecord::Migration
  def self.up
    create_table :families do |t|
      t.column :legacy_id, :integer
      t.column :name, :string, :limit => 255
      t.column :last_name, :string, :limit => 255
      t.column :suffix, :string, :limit => 25
      t.column :address1, :string, :limit => 255
      t.column :address2, :string, :limit => 255
      t.column :city, :string, :limit => 255
      t.column :state, :string, :limit => 2
      t.column :zip, :string, :limit => 10
      t.column :home_phone, :bigint
      t.column :email, :string, :limit => 255
      t.column :latitude, :double
      t.column :longitude, :double
      t.column :anniversary, :datetime
      t.column :mail_group, :string, :limit => 1
      t.column :security_token, :string, :limit => 25
      t.column :share_address, :boolean, :default => true
      t.column :share_mobile_phone, :boolean, :default => false
      t.column :share_work_phone, :boolean, :default => false
      t.column :share_fax, :boolean, :default => false
      t.column :share_email, :boolean, :default => false
      t.column :share_birthday, :boolean, :default => true
      t.column :share_anniversary, :boolean, :default => true
    end
  end

  def self.down
    drop_table :families
  end
end
