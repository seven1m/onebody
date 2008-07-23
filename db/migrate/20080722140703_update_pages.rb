class UpdatePages < ActiveRecord::Migration
  def self.up
    change_table :pages do |t|
      t.boolean :navigation, :default => true
      t.boolean :system, :default => false
    end
  end

  def self.down
    change_table :pages do |t|
      t.remove :navigation
      t.remove :system
    end
  end
end
