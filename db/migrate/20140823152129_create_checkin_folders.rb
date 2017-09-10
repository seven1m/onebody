class CreateCheckinFolders < ActiveRecord::Migration[4.2]
  def up
    create_table :checkin_folders do |t|
      t.integer :site_id
      t.integer :checkin_time_id
      t.string :name
      t.integer :sequence
      t.boolean :active, default: true
    end

    change_table :group_times do |t|
      t.integer :checkin_folder_id
      t.rename :ordering, :sequence
    end

    GroupTime.reset_column_information

    Site.each do
      CheckinTime.all.each do |checkin_time|
        index = 0
        checkin_time.group_times.where(section: nil).each do |group_time|
          index += 1
          group_time.update_attribute(:sequence, index)
        end
        checkin_time.group_times.where.not(section: nil).each do |group_time|
          folder = CheckinFolder.where(
            name: group_time.section,
            checkin_time_id: group_time.checkin_time_id
          ).first_or_create do |f|
            index += 1
            f.sequence = index
          end
          group_time.checkin_folder_id = folder.id
          group_time.checkin_time_id = nil
          group_time.save!
        end
      end
    end
  end

  def down
    Site.each do
      GroupTime.where.not(checkin_folder_id: nil).each do |group_time|
        group_time.update_attribute(:checkin_time_id, group_time.checkin_folder.checkin_time_id)
      end
    end
    drop_table :checkin_folders
    remove_column :group_times, :checkin_folder_id
  end
end
