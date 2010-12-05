class AddPaperclipColumns < ActiveRecord::Migration
  def self.up
    change_table :people do |t|
      t.string :photo_file_name, :photo_content_type
      t.string :photo_fingerprint, :limit => 50
      t.integer :photo_file_size
      t.datetime :photo_updated_at
    end
    change_table :families do |t|
      t.string :photo_file_name, :photo_content_type
      t.string :photo_fingerprint, :limit => 50
      t.integer :photo_file_size
      t.datetime :photo_updated_at
    end
    change_table :groups do |t|
      t.string :photo_file_name, :photo_content_type
      t.string :photo_fingerprint, :limit => 50
      t.integer :photo_file_size
      t.datetime :photo_updated_at
    end
    change_table :pictures do |t|
      t.string :photo_file_name, :photo_content_type
      t.string :photo_fingerprint, :limit => 50
      t.integer :photo_file_size
      t.datetime :photo_updated_at
    end
    change_table :recipes do |t|
      t.string :photo_file_name, :photo_content_type
      t.string :photo_fingerprint, :limit => 50
      t.integer :photo_file_size
      t.datetime :photo_updated_at
    end
    change_table :publications do |t|
      t.string :file_file_name, :file_content_type
      t.string :file_fingerprint, :limit => 50
      t.integer :file_file_size
      t.datetime :file_updated_at
    end
    change_table :attachments do |t|
      t.string :file_file_name, :file_content_type
      t.string :file_fingerprint, :limit => 50
      t.integer :file_file_size
      t.datetime :file_updated_at
    end
  end

  def self.down
    change_table :people do |t|
      t.remove :photo_file_name, :photo_content_type, :photo_file_size, :photo_updated_at, :photo_fingerprint
    end
    change_table :families do |t|
      t.remove :photo_file_name, :photo_content_type, :photo_file_size, :photo_updated_at, :photo_fingerprint
    end
    change_table :groups do |t|
      t.remove :photo_file_name, :photo_content_type, :photo_file_size, :photo_updated_at, :photo_fingerprint
    end
    change_table :pictures do |t|
      t.remove :photo_file_name, :photo_content_type, :photo_file_size, :photo_updated_at, :photo_fingerprint
    end
    change_table :recipes do |t|
      t.remove :photo_file_name, :photo_content_type, :photo_file_size, :photo_updated_at, :photo_fingerprint
    end
    change_table :publications do |t|
      t.remove :file_file_name, :file_content_type, :file_file_size, :file_updated_at, :file_fingerprint
    end
    change_table :attachments do |t|
      t.remove :file_file_name, :file_content_type, :file_file_size, :file_updated_at, :file_fingerprint
    end
  end
end
