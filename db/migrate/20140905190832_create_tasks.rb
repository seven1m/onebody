class CreateTasks < ActiveRecord::Migration[4.2]
  def change
    create_table :tasks do |t|
      t.string :name
      t.text :description
      t.boolean :completed, default: false
      t.date :duedate
      t.references :group
      t.references :person
      t.references :site

      t.timestamps
    end
  end
end
