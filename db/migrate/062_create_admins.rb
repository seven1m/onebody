class CreateAdmins < ActiveRecord::Migration
  def self.up
    create_table :admins do |t|
      t.column :manage_publications, :boolean, :default => false
      t.column :manage_log, :boolean, :default => false
      t.column :manage_music, :boolean, :default => false
      t.column :view_music, :boolean, :default => false
      t.column :view_hidden_properties, :boolean, :default => false
      t.column :edit_profiles, :boolean, :default => false
      t.column :manage_groups, :boolean, :default => false
      t.column :manage_shares, :boolean, :default => false
    end
    add_column :people, :admin_id, :integer
  end

  def self.down
    drop_table :admins
    remove_column :people, :admin_id
  end
end
