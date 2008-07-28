class AddShareHomePhoneToFamilies < ActiveRecord::Migration
  def self.up
    change_table :families do |t|
      t.boolean :share_home_phone, :default => true
    end
  end

  def self.down
    change_table :families do |t|
      t.remove :share_home_phone
    end
  end
end
