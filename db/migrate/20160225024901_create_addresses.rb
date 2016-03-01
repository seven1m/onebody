class CreateAddresses < ActiveRecord::Migration
  def up
    create_addresses_table
    Address.reset_column_information
    copy_data
    remove_columns_from_families_table
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end

  private

  def create_addresses_table
    create_table :addresses do |t|
      t.integer :site_id
      t.integer :family_id
      t.integer :kind
      t.string :description
      t.string :address1, :address2, :city, :state
      t.string :zip, limit: 25
      t.string :country, limit: 2
      t.float :latitude, :longitude
    end
  end

  def copy_data
    puts 'Migrating address data...'
    Site.each do
      Family.find_each do |family|
        next if family.address1.blank? && family.city.blank? && family.state.blank? && family.zip.blank?
        family.addresses.create!(
          kind:        :home,
          address1:    family.address1,
          address2:    family.address2,
          city:        family.city,
          state:       family.state,
          zip:         family.zip,
          country:     family.country,
          latitude:    family.latitude,
          longitude:   family.longitude
        )
      end
    end
  end

  def remove_columns_from_families_table
    change_table :families do |t|
      t.remove :address1, :address2, :city, :state, :zip, :country, :latitude, :longitude
    end
  end
end
