class AddStatusToPeople < ActiveRecord::Migration[4.2]
  def up
    add_column :people, :status, :integer

    Person.reset_column_information

    puts "Updating status column..."
    each_person do |person|
      next if person.deleted? || person.family.nil? || person.family.deleted?
      if person[:can_sign_in]
        if person[:full_access]
          person.status = :active
        else
          person.status = :pending
        end
      else
        person.status = :inactive
      end
      person.save(validate: false)
    end
    puts

    remove_column :people, :can_sign_in
    remove_column :people, :full_access
    remove_column :people, :visible_on_printed_directory
    remove_column :people, :visible_to_everyone
  end

  def down
    add_column :people, :can_sign_in, :boolean, default: false
    add_column :people, :full_access, :boolean, default: false
    add_column :people, :visible_on_printed_directory, :boolean, default: false
    add_column :people, :visible_to_everyone, :boolean, default: false

    Person.reset_column_information

    puts "Updating visibility columns..."
    each_person do |person|
      next if person.deleted? || person.family.nil? || person.family.deleted?
      if person.active?
        person.can_sign_in = true
        person.full_access = true
        person.visible_on_printed_directory = true
        person.visible_to_everyone = true
      elsif person.pending?
        person.can_sign_in = true
        person.full_access = false
        person.visible_on_printed_directory = false
        person.visible_to_everyone = true
      end
      person.save(validate: false)
    end
    puts

    remove_column :people, :status
  end

  private

  def each_person
    Site.each do
      count = Person.count
      index = 0
      Person.find_each do |person|
        index += 1
        print "#{index} of #{count}\r"
        yield(person)
      end
    end
  end
end
