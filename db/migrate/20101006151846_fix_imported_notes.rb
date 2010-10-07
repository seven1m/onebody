class FixImportedNotes < ActiveRecord::Migration
  def self.up
    Site.each do
      Note.all(:conditions => "original_url like '%facebook.com%' or original_url like '%twitter.com%'").each do |note|
        if stream_item = StreamItem.find_by_streamable_type_and_streamable_id('Note', note.id)
          stream_item.title = nil
          stream_item.save
        end
        note.title = nil
        note.save
      end
    end
  end

  def self.down
  end
end
