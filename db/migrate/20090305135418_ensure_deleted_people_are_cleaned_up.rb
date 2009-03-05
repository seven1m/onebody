class EnsureDeletedPeopleAreCleanedUp < ActiveRecord::Migration
  def self.up
    Site.each do
      Person.update_all(
        "email = null, alternate_email = null, twitter_account = null",
        ["deleted = ?", true]
      )
    end
  end

  def self.down
  end
end
