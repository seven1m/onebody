class CreateNotes < ActiveRecord::Migration
  def self.up
    create_table :notes do |t|
      t.column :person_id, :integer
      t.column :group_id, :integer
      t.column :title, :string, :limit => 255
      t.column :body, :text
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :original_url, :string, :limit => 255
      t.column :deleted, :boolean, :default => false
    end
  end

  def self.down
    drop_table :notes
  end
end
