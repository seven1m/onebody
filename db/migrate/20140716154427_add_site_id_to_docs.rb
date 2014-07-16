class AddSiteIdToDocs < ActiveRecord::Migration
  def change
    change_table :documents do |t|
      t.integer :site_id
    end
    change_table :document_folders do |t|
      t.integer :site_id
    end
  end
end
