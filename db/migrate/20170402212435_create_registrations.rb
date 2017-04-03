class CreateRegistrations < ActiveRecord::Migration
  def change
    create_table :registrations do |t|
      t.belongs_to :site, index: true
      t.belongs_to :event, index: true
      t.belongs_to :person, index: true
      t.integer :status, default: 0
      t.decimal :total_cost

      t.timestamps null: false
    end
  end
end
