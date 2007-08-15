class CreateFeeds < ActiveRecord::Migration
  def self.up
    create_table :feeds do |t|
      t.column :person_id, :integer
      t.column :group_id, :integer
      t.column :name, :string, :limit => 255
      t.column :url, :string, :limit => 500
      t.column :spec, :string, :limit => 5
      t.column :fetched_at, :datetime
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :feeds
  end
end
