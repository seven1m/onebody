class UpdateTwitterMessage < ActiveRecord::Migration
  def self.up
    change_table :twitter_messages do |t|
      t.string :twitter_message_id
    end
  end

  def self.down
    change_table :twitter_messages do |t|
      t.remove :twitter_message_id
    end
  end
end
