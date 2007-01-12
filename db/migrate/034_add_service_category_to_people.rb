class AddServiceCategoryToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :service_category, :string, :limit => 100
  end

  def self.down
    remove_column :people, :service_category
  end
end
