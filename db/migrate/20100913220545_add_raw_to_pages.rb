class AddRawToPages < ActiveRecord::Migration
  def self.up
    change_table :pages do |t|
      t.boolean :raw, :default => false
    end
  end

  def self.down
    change_table :pages do |t|
      t.remove :raw
    end
  end
end
