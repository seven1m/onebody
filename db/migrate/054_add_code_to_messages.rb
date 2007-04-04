class AddCodeToMessages < ActiveRecord::Migration
  def self.up
    add_column :messages, :code, :integer
    Message.find(:all).each { |m| m.before_create; m.dont_send = true; m.save }
  end

  def self.down
    remove_column :messages, :code
  end
end
