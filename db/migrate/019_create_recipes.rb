class CreateRecipes < ActiveRecord::Migration
  def self.up
    create_table :recipes do |t|
      t.column :person_id, :integer
      t.column :title, :string 
      t.column :notes, :text
      t.column :description, :text
      t.column :ingredients, :text
      t.column :directions, :text
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :prep, :string
      t.column :bake, :string
      t.column :serving_size, :integer
    end
  end

  def self.down
    drop_table :recipes
  end
end
