class EnsureAllPeopleHaveAFeedCode < ActiveRecord::Migration
  def self.up
    Site.each do
      Person.find_all_by_feed_code(nil).each do |person|
        person.update_feed_code
        person.save(false) # no validation
      end
    end
  end

  def self.down
  end
end
