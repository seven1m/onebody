class UpdateSharing < ActiveRecord::Migration
  def self.up
    add_column :people, :share_anniversary, :boolean, :default => true
    add_column :people, :share_address, :boolean, :default => true
    add_column :people, :share_home_phone, :boolean, :default => true
    Person.reset_column_information
    Site.each do
      Person.where("                               (select count(*) from families where id=people.family_id) > 0").update_all("share_address      = (select share_address      from families where id=people.family_id)")
      Person.where("                               (select count(*) from families where id=people.family_id) > 0").update_all("share_home_phone   = (select share_home_phone   from families where id=people.family_id)")
      Person.where("                               (select count(*) from families where id=people.family_id) > 0").update_all("share_anniversary  = (select share_anniversary  from families where id=people.family_id)")
      Person.where("share_mobile_phone is null and (select count(*) from families where id=people.family_id) > 0").update_all("share_mobile_phone = (select share_mobile_phone from families where id=people.family_id)")
      Person.where("share_work_phone is null   and (select count(*) from families where id=people.family_id) > 0").update_all("share_work_phone   = (select share_work_phone   from families where id=people.family_id)")
      Person.where("share_fax is null          and (select count(*) from families where id=people.family_id) > 0").update_all("share_fax          = (select share_fax          from families where id=people.family_id)")
      Person.where("share_email is null        and (select count(*) from families where id=people.family_id) > 0").update_all("share_email        = (select share_email        from families where id=people.family_id)")
      Person.where("share_birthday is null     and (select count(*) from families where id=people.family_id) > 0").update_all("share_birthday     = (select share_birthday     from families where id=people.family_id)")
      Person.where("share_activity is null     and (select count(*) from families where id=people.family_id) > 0").update_all("share_activity     = (select share_activity     from families where id=people.family_id)")
    end
    change_column_default :people, :share_address,      true
    change_column_default :people, :share_home_phone,   true
    change_column_default :people, :share_anniversary,  true
    change_column_default :people, :share_mobile_phone, false
    change_column_default :people, :share_work_phone,   false
    change_column_default :people, :share_fax,          false
    change_column_default :people, :share_email,        false
    change_column_default :people, :share_birthday,     true
    change_column_default :people, :share_activity,     true
    remove_column :families, :share_address
    remove_column :families, :share_home_phone
    remove_column :families, :share_anniversary
    remove_column :families, :share_mobile_phone
    remove_column :families, :share_work_phone
    remove_column :families, :share_fax
    remove_column :families, :share_email
    remove_column :families, :share_birthday
    remove_column :families, :share_activity
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
