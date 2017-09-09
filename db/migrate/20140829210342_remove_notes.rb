class RemoveNotes < ActiveRecord::Migration[4.2]
  def up
    remove_reference :comments, :note
    drop_table :notes
    Site.each do
      StreamItem.where(streamable_type: 'Note').delete_all
    end
  end

  def down
    create_table 'notes' do |t|
      t.integer  'person_id'
      t.string   'title'
      t.text     'body'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.string   'original_url'
      t.integer  'group_id'
      t.integer  'site_id'
    end
    add_reference :comments, :note
  end
end
