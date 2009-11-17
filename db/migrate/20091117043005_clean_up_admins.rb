class CleanUpAdmins < ActiveRecord::Migration
  def self.up
    Site.each do
      Person.all(:conditions => 'admin_id is not null').each do |person|
        unless person.admin
          person.update_attribute(:admin_id, nil)
        end
      end
    end
  end

  def self.down
  end
end
