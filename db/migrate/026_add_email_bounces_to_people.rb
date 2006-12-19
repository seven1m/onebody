class AddEmailBouncesToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :email_bounces, :integer, :default => 0
  end

  def self.down
    remove_column :people, :email_bounces
  end
end
