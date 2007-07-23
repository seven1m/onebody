class AddStaffAndElderToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :member, :boolean, :default => false
    add_column :people, :staff, :boolean, :default => false
    add_column :people, :elder, :boolean, :default => false
    add_column :people, :deacon, :boolean, :default => false
    add_column :people, :can_sign_in, :boolean, :default => false
    add_column :people, :visible_to_everyone, :boolean, :default => false
    add_column :people, :visible_on_printed_directory, :boolean, :default => false
    add_column :people, :full_access, :boolean, :default => false
  end

  def self.down
    remove_column :people, :member
    remove_column :people, :staff
    remove_column :people, :elder
    remove_column :people, :deacon
    remove_column :people, :can_sign_in
    remove_column :people, :visible_to_everyone
    remove_column :people, :visible_on_printed_directory
    remove_column :people, :full_access
  end
end
