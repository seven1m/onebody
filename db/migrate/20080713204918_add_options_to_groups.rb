class AddOptionsToGroups < ActiveRecord::Migration
  def self.up
    change_table :groups do |t|
      t.boolean :blog, :email, :prayer, :default => true
    end
  end

  def self.down
    change_table :groups do |t|
      t.remove :blog, :email, :prayer
    end
  end
end
