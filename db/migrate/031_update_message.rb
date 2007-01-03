class UpdateMessage < ActiveRecord::Migration
  def self.up
    rename_column :messages, :to_id, :to_person_id
  end

  def self.down
    rename_column :messages, :to_person_id, :to_id
  end
end
