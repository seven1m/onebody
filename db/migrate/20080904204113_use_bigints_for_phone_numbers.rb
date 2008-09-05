class UseBigintsForPhoneNumbers < ActiveRecord::Migration
  def self.up
    change_column :people,   :mobile_phone,  :bigint
    change_column :people,   :work_phone,    :bigint
    change_column :people,   :fax,           :bigint
    change_column :people,   :service_phone, :bigint
    change_column :families, :home_phone,    :bigint
  end

  def self.down
    change_column :people,   :mobile_phone,  :integer
    change_column :people,   :work_phone,    :integer
    change_column :people,   :fax,           :integer
    change_column :people,   :service_phone, :integer
    change_column :families, :home_phone,    :integer
  end
end
