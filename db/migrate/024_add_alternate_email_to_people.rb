class AddAlternateEmailToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :alternate_email, :string, :limit => 255
  end

  def self.down
    remove_column :people, :alternate_email
  end
end
