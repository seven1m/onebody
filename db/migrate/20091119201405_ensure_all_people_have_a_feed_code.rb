class EnsureAllPeopleHaveAFeedCode < ActiveRecord::Migration
  def self.up
    Site.each do
      Person.where(feed_code: nil).each do |person|
        person.update_feed_code
        person.save(:validate => false) # no validation
      end
    end
  end

  def self.down
  end
end
