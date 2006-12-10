class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table :people do |t|
      t.column :legacy_id, :integer
      t.column :family_id, :integer
      t.column :sequence, :integer
      t.column :gender, :string, :limit => 6
      t.column :first_name, :string, :limit => 255
      t.column :last_name, :string, :limit => 255
      t.column :suffix, :string, :limit => 25
      t.column :mobile_phone, :bigint
      t.column :work_phone, :bigint
      t.column :fax, :bigint
      t.column :birthday, :datetime
      t.column :email, :string, :limit => 255
      t.column :email_changed, :boolean, :default => false
      t.column :website, :string, :limit => 255
      t.column :classes, :string, :limit => 255
      t.column :shepherd, :string, :limit => 255
      t.column :mail_group, :string, :limit => 1
      t.column :encrypted_password, :string, :limit => 100
      t.column :service_name, :string, :limit => 100
      t.column :service_description, :text
      t.column :service_phone, :bigint
      t.column :service_email, :string, :limit => 255
      t.column :service_website, :string, :limit => 255
      t.column :activities, :text
      t.column :interests, :text
      t.column :music, :text
      t.column :tv_shows, :text
      t.column :movies, :text
      t.column :books, :text
      t.column :quotes, :text
      t.column :about, :text
      t.column :testimony, :text
      t.column :share_mobile_phone, :boolean
      t.column :share_work_phone, :boolean
      t.column :share_fax, :boolean
      t.column :share_email, :boolean
      t.column :share_birthday, :boolean
    end
  end

  def self.down
    drop_table :people
  end
end
