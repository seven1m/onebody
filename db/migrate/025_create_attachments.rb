class CreateAttachments < ActiveRecord::Migration
  def self.up
    create_table :attachments do |t|
      t.column :message_id, :integer
      t.column :name, :string, :limit => 255
      t.column :file, :binary, :limit => 10.megabyte
      t.column :content_type, :string, :limit => 50
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :attachments
  end
end
