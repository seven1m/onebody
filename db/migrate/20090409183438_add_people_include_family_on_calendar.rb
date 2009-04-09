class AddPeopleIncludeFamilyOnCalendar < ActiveRecord::Migration
  def self.up
    change_table :people do |t|
      t.boolean :include_family_on_calendar, :default => true
    end
  end

  def self.down
  	change_table :people do |t|
      t.remove :include_family_on_calendar
    end
  end
end
