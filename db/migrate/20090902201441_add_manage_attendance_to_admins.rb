class AddManageAttendanceToAdmins < ActiveRecord::Migration
  def self.up
    change_table :admins do |t|
      t.boolean :manage_attendance, :default => false
    end
  end

  def self.down
    change_table :admins do |t|
      t.remove :manage_attendance
    end
  end
end
