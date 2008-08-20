class MoreSecurePasswords < ActiveRecord::Migration
  def self.up
    change_table :people do |t|
      t.string :salt, :limit => 50
    end
    Site.each do |site|
      Person.all.each do |person|
        unless person.encrypted_password.nil?
          person.encrypted_password = person.encrypt_second_pass(person.encrypted_password)
          person.save
        end
      end
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, "Passwords cannot be reverted to old encryption."
  end
end
