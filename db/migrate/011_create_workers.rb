class CreateWorkers < ActiveRecord::Migration
  def self.up
    create_table :workers do |t|
      t.column :ministry_id, :integer
      t.column :person_id, :integer
      t.column :start, :datetime
      t.column :end, :datetime
      t.column :remind_on, :datetime
      t.column :reminded, :boolean, :default => false
    end
  end

  def self.down
    drop_table :workers
  end
end
