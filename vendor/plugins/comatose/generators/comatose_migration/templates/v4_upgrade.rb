class <%= class_name %> < ActiveRecord::Migration

  # Upgrades schema from version 0.3 to version 0.4 
  def self.up
    add_column :comatose_pages, "filter_type", :string, :limit => 25, :default => "Textile"
    add_column :comatose_pages, "keywords", :string, :limit => 1000
  end

  # Downgrades schema from version 0.4 to version 0.3
  def self.down
    remove_column :comatose_pages, "filter_type"
    remove_column :comatose_pages, "keywords"
  end

end
