class CreateContacts < ActiveRecord::Migration
  def self.up
    create_table :contacts do |t|
      t.column :person_id, :integer
      t.column :owner_id, :integer
    end
  end

  def self.down
    drop_table :contacts
  end
end
