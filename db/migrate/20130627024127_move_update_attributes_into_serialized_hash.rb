class MoveUpdateAttributesIntoSerializedHash < ActiveRecord::Migration
  def up
    change_table :updates do |t|
      t.text :data
      t.text :diff
    end

    Update.reset_column_information
    Site.each do
      Update.find_each do |update|
        hash = {
          person: {
            first_name:    update.first_name,
            last_name:     update.last_name,
            suffix:        update.suffix,
            gender:        update.gender,
            mobile_phone:  update.mobile_phone,
            work_phone:    update.work_phone,
            fax:           update.fax,
            birthday:      nilify(update.birthday),
            anniversary:   nilify(update.anniversary),
            custom_fields: update.custom_fields,
          }.reject { |_, v| v.nil? },
          family: {
            name:          update.family_name,
            last_name:     update.family_last_name,
            home_phone:    update.home_phone,
            address1:      update.address1,
            address2:      update.address2,
            city:          update.city,
            state:         update.state,
            zip:           update.zip,
          }.reject { |_, v| v.nil? }
        }.reject { |_, v| v.empty? }

        update.data = hash
        update.save(validate: false)
      end
    end

    change_table :updates do |t|
      t.remove :first_name, :last_name, :suffix, :gender,
               :mobile_phone, :work_phone, :fax,
               :birthday, :anniversary,
               :custom_fields,
               :family_name, :family_last_name,
               :home_phone,
               :address1, :address2,
               :city, :state, :zip
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def nilify(date)
    return nil if date.nil? or date.year == 1800
    date
  end
end
