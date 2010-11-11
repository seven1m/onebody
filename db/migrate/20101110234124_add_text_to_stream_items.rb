class AddTextToStreamItems < ActiveRecord::Migration
  change_table :stream_items do |t|
    t.boolean :text, :default => false
  end
  StreamItem.reset_column_information
  def self.up
    Site.each do
      Message.all.each do |message|
        message.update_stream_items
      end
    end
  end

  def self.down
  change_table :stream_items do |t|
    t.remove :text
  end
  end
end
