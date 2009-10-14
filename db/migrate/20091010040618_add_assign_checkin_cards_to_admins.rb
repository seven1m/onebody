class AddAssignCheckinCardsToAdmins < ActiveRecord::Migration
  def self.up
    change_table :admins do |t|
      t.boolean :assign_checkin_cards, :default => false
    end
  end

  def self.down
    change_table :admins do |t|
      t.remove :assign_checkin_cards
    end
  end
end
