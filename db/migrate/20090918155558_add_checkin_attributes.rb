class AddCheckinAttributes < ActiveRecord::Migration
  def self.up
    change_table :groups do |t|
      t.integer :checkin_order, :default => 0
      t.boolean :checkin_destination, :default => false
      t.integer :checkin_weekday # 0=sunday
      t.datetime :checkin_datetime # specific date (mutually exclusive from above weekday attribute)
    end
    change_table :attendance_records do |t|
      t.string :barcode_id, :limit => 50
      t.string :first_name, :last_name, :family_name, :age, :limit => 255
      t.string :can_pick_up, :limit => 100
      t.string :cannot_pick_up, :limit => 100
      t.string :medical_notes, :limit => 200
    end
    unless Person.columns.detect { |c| c.name == 'barcode_id' } # checkin plugin might have been installed before
      change_table :people do |t|
        t.string :barcode_id, :limit => 50
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
    change_table :groups do |t|
      t.remove :checkin_order
      t.remove :checkin_destination
      t.remove :checkin_weekday
      t.remove :checkin_datetime
    end
    change_table :attendance_records do |t|
      t.remove :barcode_id
      t.remove :first_name, :last_name, :family_name, :age
      t.remove :can_pick_up
      t.remove :cannot_pick_up
      t.remove :medical_notes
    end
    change_table :people do |t|
      t.remove :barcode_id
      t.remove :can_pick_up
      t.remove :cannot_pick_up
      t.remove :medical_notes
    end
    change_table :admins do |t|
      t.remove :manage_checkin
    end
  end
end
