class CreateCheckinLabels < ActiveRecord::Migration[4.2]
  def change
    create_table :checkin_labels do |t|
      t.string :name
      t.string :description, limit: 1000
      t.text :xml
      t.integer :site_id

      t.timestamps
    end

    change_table :group_times do |t|
      t.integer :label_id
    end

    Site.each do
      default = CheckinLabel.create!(
        name: 'Default',
        xml: '<file src="default.xml"/>'
      )
      GroupTime.reorder(:id).all.each do |group_time|
        if group_time.print_nametag?
          group_time.update_attribute(:label_id, default.id)
        end
      end
    end

    change_table :group_times do |t|
      t.remove :print_nametag
    end
    change_table :attendance_records do |t|
      t.remove :print_nametag
      t.integer :label_id
    end
  end
end
