class LowercaseAllEmails < ActiveRecord::Migration
  def up
    Site.each do
      Person.find_each do |person|
        person.email = person.email.downcase if person.email.present?
        person.alternate_email = person.alternate_email.downcase if person.alternate_email.present?
        person.save(validate: false) if person.changed?
      end
    end
  end

  def down
  end
end
