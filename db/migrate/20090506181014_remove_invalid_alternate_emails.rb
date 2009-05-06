class RemoveInvalidAlternateEmails < ActiveRecord::Migration
  def self.up
    Site.each do
      Person.all(:conditions => "alternate_email is not null and alternate_email != ''").each do |person|
        unless person.alternate_email =~ VALID_EMAIL_ADDRESS
          if (s = person.alternate_email.strip) =~ VALID_EMAIL_ADDRESS # try this first
            person.update_attributes!(:alternate_email => s)
          else
            person.update_attributes!(:alternate_email => nil)
          end
        end
      end
    end
  end

  def self.down
  end
end
