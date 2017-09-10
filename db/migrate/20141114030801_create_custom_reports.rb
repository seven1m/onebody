class CreateCustomReports < ActiveRecord::Migration[4.2]
  def change
    create_table :custom_reports do |t|
      t.integer :site_id
      t.string :title
      t.string :category
      t.text :header
      t.text :body
      t.text :footer
      t.string :filters
    end
  end
end
