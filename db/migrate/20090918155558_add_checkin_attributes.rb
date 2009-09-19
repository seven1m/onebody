class AddCheckinAttributes < ActiveRecord::Migration
  def self.up
    change_table :attendance_records do |t|
      t.string :first_name, :last_name, :family_name, :age, :limit => 255
      t.string :can_pick_up, :limit => 100
      t.string :cannot_pick_up, :limit => 100
      t.string :medical_notes, :limit => 200
    end
    if Person.columns.detect { |c| c.name == 'barcode_id' } # checkin plugin might have been installed before
      change_table :people do |t|
        t.remove :barcode_id
      end
    else
      change_table :people do |t|
        t.string :can_pick_up, :limit => 100
        t.string :cannot_pick_up, :limit => 100
        t.string :medical_notes, :limit => 200
      end
      change_table :admins do |t|
        t.boolean :manage_checkin, :default => false
      end
    end
  end

  def self.down
    change_table :attendance_records do |t|
      t.remove :first_name, :last_name, :family_name, :age
      t.remove :can_pick_up
      t.remove :cannot_pick_up
      t.remove :medical_notes
    end
    change_table :people do |t|
      t.remove :can_pick_up
      t.remove :cannot_pick_up
      t.remove :medical_notes
    end
    change_table :admins do |t|
      t.remove :manage_checkin
    end
  end
end
