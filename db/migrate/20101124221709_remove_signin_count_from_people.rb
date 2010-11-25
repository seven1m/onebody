class RemoveSigninCountFromPeople < ActiveRecord::Migration
  def self.up
    change_table :people do |t|
      t.remove :signin_count
    end
  end

  def self.down
    change_table :people do |t|
      t.integer :signin_count, :default => 0
    end
  end
end
