class RenamePeopleServices < ActiveRecord::Migration
  def self.up
    change_table :people do |t|
      t.rename :service_name,        :business_name
      t.rename :service_description, :business_description
      t.rename :service_phone,       :business_phone
      t.rename :service_address,     :business_address
      t.rename :service_email,       :business_email
      t.rename :service_website,     :business_website
      t.rename :service_category,    :business_category
    end
  end

  def self.down
    change_table :people do |t|
      t.rename :business_name,        :service_name
      t.rename :business_description, :service_description
      t.rename :business_phone,       :service_phone
      t.rename :business_address,     :service_address
      t.rename :business_email,       :service_email
      t.rename :business_website,     :service_website
      t.rename :business_category,    :service_category
    end
  end
end
