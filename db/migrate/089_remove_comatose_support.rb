class RemoveComatoseSupport < ActiveRecord::Migration
  def self.up
    begin
      drop_table :comatose_pages
      drop_table :page_versions
    rescue
      # only works for old installs of OneBody
    end
  end

  def self.down
  end
end
