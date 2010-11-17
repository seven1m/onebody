class AddLogoAttachmentToSites < ActiveRecord::Migration
  def self.up
    change_table :sites do |t|
      t.string :logo_file_name, :logo_content_type
      t.string :logo_fingerprint, :limit => 50
      t.integer :logo_file_size
      t.datetime :logo_updated_at
    end
  end

  def self.down
    change_table :people do |t|
      t.remove :logo_file_name, :logo_content_type, :logo_file_size, :logo_updated_at, :logo_fingerprint
    end
  end
end
