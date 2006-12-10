class CreateMemberships < ActiveRecord::Migration
  def self.up
    create_table :memberships do |t|
      t.column :group_id, :integer
      t.column :person_id, :integer
      t.column :admin, :boolean, :default => false
      t.column :get_email, :boolean, :default => true
      t.column :share_address, :boolean
      t.column :share_mobile_phone, :boolean
      t.column :share_work_phone, :boolean
      t.column :share_fax, :boolean
      t.column :share_email, :boolean
      t.column :share_birthday, :boolean
      t.column :share_anniversary, :boolean
    end
  end

  def self.down
    drop_table :memberships
  end
end
