class RevampAdmins < ActiveRecord::Migration
  def self.up
    privilege_columns = Admin.columns.map { |c| c.name }.reject { |c| %w(id created_at updated_at site_id flags template_name).include?(c) }
    change_table :admins do |t|
      t.string :template_name, :limit => 100
      t.text :flags
    end
    Admin.reset_column_information
    Site.each do
      Admin.all.each do |admin|
        admin.ensure_flags_is_hash
        privilege_columns.each do |col|
          admin.flags[col] = true if [true, 'true', 't', 1].include?(admin.read_attribute(col))
        end
        admin.save!
      end
    end
    change_table :admins do |t|
      t.remove *privilege_columns
    end
  end

  def self.down
    change_table "admins" do |t|
      t.boolean  "view_hidden_profiles",   :default => false
      t.boolean  "view_hidden_properties", :default => false
      t.boolean  "view_log",               :default => false
      t.boolean  "edit_pages",             :default => false
      t.boolean  "import_data",            :default => false
      t.boolean  "export_data",            :default => false
      t.boolean  "edit_profiles",          :default => false
      t.boolean  "manage_publications",    :default => false
      t.boolean  "manage_groups",          :default => false
      t.boolean  "manage_notes",           :default => false
      t.boolean  "manage_messages",        :default => false
      t.boolean  "manage_comments",        :default => false
      t.boolean  "manage_recipes",         :default => false
      t.boolean  "manage_pictures",        :default => false
      t.boolean  "manage_access",          :default => false
      t.boolean  "manage_updates",         :default => false
      t.boolean  "manage_checkin",         :default => false
      t.boolean  "manage_news",            :default => false
      t.boolean  "manage_attendance",      :default => false
      t.boolean  "assign_checkin_cards",   :default => false
    end
    Admin.reset_column_information
    Site.each do
      Admin.all.each do |admin|
        admin.flags.each do |flag, value|
          if Admin.columns.map { |c| c.name }.include?(flag.to_s)
            admin.send("#{flag}=", value)
          end
        end
        admin.save!
      end
    end
    change_table :admins do |t|
      t.remove :template_name
      t.remove :flags
    end
  end
end
