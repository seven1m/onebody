class AddHtmlBodyToMessages < ActiveRecord::Migration
  def self.up
    change_table :messages do |t|
      t.text :html_body
    end
  end

  def self.down
    change_table :messages do |t|
      t.remove :html_body
    end
  end
end
