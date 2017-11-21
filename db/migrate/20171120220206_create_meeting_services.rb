class CreateMeetingServices < ActiveRecord::Migration[5.1]
  def change
    create_table :meeting_services do |t|
      t.string :name
      t.integer :meeting_id, foreign_key: true

      t.timestamps
    end
  end
end
