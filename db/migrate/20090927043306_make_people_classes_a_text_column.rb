class MakePeopleClassesATextColumn < ActiveRecord::Migration
  def self.up
    remove_index "people", :name => "index_people_on_classes"
    change_column :people, :classes, :text
  end

  def self.down
    change_column :people, :classes, :string
    add_index "people", ["classes"], :name => "index_people_on_classes"
  end
end
