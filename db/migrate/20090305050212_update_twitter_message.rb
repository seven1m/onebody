class UpdateTwitterMessage < ActiveRecord::Migration
  def self.up
    change_table :twitter_messages do |t|
      t.string :twitter_message_id
    end
    change_table :sites do |t|
      t.boolean :twitter_enabled, :default => false
    end
    Setting.all.select { |s| s.name =~ /^Twitter|^Jabber/ }.each { |s| s.destroy }
  end

  def self.down
    change_table :twitter_messages do |t|
      t.remove :twitter_message_id
    end
    change_table :sites do |t|
      t.remove :twitter_enabled
    end
  end
end
