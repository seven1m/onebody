# Example Connector
# run with: script/sync example

# This is an example connector and doesn't actually do anything
# useful except serve as a basis for your own connector.

# For a more involved (and perhaps convoluted) connector, see coms.rb.

require File.dirname(__FILE__) + '/base'

# do your own requires of external libraries if needed

# change "Example" below to match the filename of this connector
class ExampleConnector < ExternalDataConnector
  def initialize
    # do your database setup here
    
    # if your connector needs arguments passed from the command line,
    # they can be specified like so:
    # script/sync example arg1 arg2 arg3
    # each argugment will be passed in order to this method
    # you will need to change this method to accept them
  end
  
  def people_ids
    # array of ids of currently active people (legacy id, i.e. id from external source)
  end
  
  def family_ids
    # array of ids of currently active families (legacy id, i.e. id from external source)
  end

  def each_person(updated_since)
    # for each person in external database, yield to the given block
    # a hash like the following
    
    # this method should only return people who've been updated since
    # the specified date; of course, you can ignore the updated_since
    # arg and simply return all people every time, but that's not
    # recommended unless your database is really small
    
    # (do some work here to get the people)
    people.each do |person|
      yield({
        :legacy_id                    => person.legacy_id,                    # id from external database
        :legacy_family_id             => person.legacy_family_id,             # family_id from external database
        :sequence                     => person.sequence,                     # order of person in family (father usually first, then mother, then children in order of birth)
        :gender                       => person.gender,                       # 'Male', 'Female' for adults; 'Boy', 'Girl' for children
        :first_name                   => person.first_name, 
        :last_name                    => person.last_name,
        :suffix                       => person.suffix,                       # 'Jr.', 'Sr.', 'II', etc.
        :mobile_phone                 => person.mobile_phone,
        :work_phone                   => person.work_phone,
        :fax                          => person.fax,
        :birthday                     => person.birthday,
        :email                        => person.email,
        :classes                      => person.classes,                      # comma-separated list of class codes (used to link online groups with external source)
        :mail_group                   => person.mail_group,                   # single-character mailing code, e.g. 'M', 'A', 'P'
        :anniversary                  => person.anniversary,
        :member                       => person.member,                       # true/false
        :staff                        => person.staff,                        # true/false
        :elder                        => person.elder,                        # true/false
        :deacon                       => person.deacon,                       # true/false
        :can_sign_in                  => person.can_sign_in,                  # true/false
        :visible_to_everyone          => person.visible_to_everyone,          # true/false (overridden by individual user privacy settings)
        :visible_on_printed_directory => person.visible_on_printed_directory, # true/false
        :full_access                  => person.full_access                   # true/false
      })
    end
  end
  
  def each_family(updated_since)
    # for each family in external database, yield to the given block
    # a hash like the following
    
    # this method should only return families who've been updated since
    # the specified date; of course, you can ignore the updated_since
    # arg and simply return all families every time, but that's not
    # recommended unless your database is really small
    
    # (do some work here to get the families)
    families.each do |family|
      yield({
        :legacy_id  => family.legacy_id,  # id from external database
        :name       => family.name,       # should be family name, e.g. 'Tim & Jennie Morgan'
        :last_name  => family.last_name,  # e.g. 'Morgan'
        :suffix     => family.suffix,     # 'Jr.', 'Sr.', 'II', etc.
        :address1   => family.address1,
        :address2   => family.address2,
        :city       => family.city,
        :state      => family.state,      # two-letter postal state, e.g. 'OK'
        :zip        => family.zip,
        :home_phone => family.home_phone,
        :email      => family.email,      # family email, if applicable
        :mail_group => family.mail_group  # single-character mailing code for family, e.g. 'M', 'A', 'P'
      })
    end
  end
end