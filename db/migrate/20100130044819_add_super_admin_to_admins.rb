class AddSuperAdminToAdmins < ActiveRecord::Migration
  def self.up
    change_table :admins do |t|
      t.boolean :super_admin, :default => false
    end
    Admin.reset_column_information
    Site.each do
      Setting.get(:access, :super_admins).to_a.each do |email|
        Person.where(email: email).each do |person|
          admin = Admin.create!(:super_admin => true)
          person.admin = admin
          person.save!
        end
      end
    end
    Setting.delete_all("section = 'Access' and name = 'Super Admins'")
  end

  def self.down
    Site.each do |site|
      site.settings.create!(
        :section => 'Access',
        :name    => 'Super Admins',
        :format  => 'list',
        :value   => Admin.where(super_admin: true).all.map { |a| a.person.email }
      )
    end
    change_table :admins do |t|
      t.remove :super_admin
    end
  end
end
