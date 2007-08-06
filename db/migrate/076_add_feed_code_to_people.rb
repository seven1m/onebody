class AddFeedCodeToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :feed_code, :string, :limit => 50
    Person.find(:all).each do |person|
      person.update_feed_code
      person.save
    end
  end

  def self.down
    remove_column :people, :feed_code
  end
end
