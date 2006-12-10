class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.column :group_id, :integer
      t.column :person_id, :integer
      t.column :to_id, :integer
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :parent_id, :integer
      t.column :subject, :string, :limit => 255
      t.column :body, :text
      t.column :share_email, :boolean, :default => false
    end
  end

  def self.down
    drop_table :messages
  end
end
