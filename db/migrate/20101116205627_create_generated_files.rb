class CreateGeneratedFiles < ActiveRecord::Migration
  def self.up
    create_table :generated_files do |t|
      t.integer :site_id
      t.integer :job_id
      t.integer :person_id
      t.string :file_file_name, :file_content_type
      t.string :file_fingerprint, :limit => 50
      t.integer :file_file_size
      t.datetime :file_updated_at
      t.timestamps
    end
  end

  def self.down
    drop_table :generated_files
  end
end
