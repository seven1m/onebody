class AddIndexBusinessCategoryOnPeople < ActiveRecord::Migration
  def self.up
    add_index "people", ["business_category"], :name => "index_business_category_on_people"
  end

  def self.down
    remove_index "people", :name => "index_business_category_on_people"
  end
end
