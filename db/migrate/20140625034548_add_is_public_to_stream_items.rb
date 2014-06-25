class AddIsPublicToStreamItems < ActiveRecord::Migration
  def change
    change_table :stream_items do |t|
      t.boolean :is_public, false
    end
  end
end
