class AddSharingToMemberships < ActiveRecord::Migration
  def self.up
    add_column    :memberships, :share_home_phone,   :boolean, :default => false
    change_column :memberships, :share_address,      :boolean, :default => false
    change_column :memberships, :share_mobile_phone, :boolean, :default => false
    change_column :memberships, :share_work_phone,   :boolean, :default => false
    change_column :memberships, :share_fax,          :boolean, :default => false
    change_column :memberships, :share_email,        :boolean, :default => false
    change_column :memberships, :share_birthday,     :boolean, :default => false
    change_column :memberships, :share_anniversary,  :boolean, :default => false
    Site.each do
      Membership.all.each do |membership|
        membership.update_attributes!(
          :share_home_phone   => false,
          :share_address      => false,
          :share_mobile_phone => false,
          :share_work_phone   => false,
          :share_fax          => false,
          :share_email        => false,
          :share_birthday     => false,
          :share_anniversary  => false
        )
      end
    end
  end

  def self.down
    remove_column :memberships, :share_home_phone
  end
end
