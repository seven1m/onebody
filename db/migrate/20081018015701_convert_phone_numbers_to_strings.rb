class ConvertPhoneNumbersToStrings < ActiveRecord::Migration
  def self.up
    change_column :people,   :mobile_phone,  :string, :limit => 25
    change_column :people,   :work_phone,    :string, :limit => 25
    change_column :people,   :fax,           :string, :limit => 25
    change_column :people,   :service_phone, :string, :limit => 25
    change_column :families, :home_phone,    :string, :limit => 25
    change_column :updates,  :mobile_phone,  :string, :limit => 25
    change_column :updates,  :work_phone,    :string, :limit => 25
    change_column :updates,  :fax,           :string, :limit => 25
    change_column :updates,  :home_phone,    :string, :limit => 25
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, "Can't convert phone numbers back to integers."
  end
end
