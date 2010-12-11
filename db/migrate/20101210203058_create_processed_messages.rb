class CreateProcessedMessages < ActiveRecord::Migration
  def self.up
    create_table :processed_messages do |t|
      t.string :header_message_id
      t.timestamps
    end
  end

  def self.down
    drop_table :processed_messages
  end
end
