# This class doesn't do much yet except to serve as a template for your connector.
# See coms.rb for an example

class ExternalDataConnector
  
  def logger; RAILS_DEFAULT_LOGGER; end
  
  def initialize
    # do your database setup here
  end
  
  def people_ids
    # array of ids of currently active people
  end
  
  def family_ids
    # array of ids of currently active families
  end

  def each_person(updated_since)
    # for each person in external database, yield to the given block
    # a hash with the following keys (as symbols):
    
    # this method should only return people who've been updated since
    # the specified date; of course, you can ignore the updated_since
    # arg and simply return all people every time, but that's not
    # recommended unless your database is really small
    
    # :legacy_id                    id from external database
    # :legacy_family_id             family_id from external database
    # :sequence                     order of person in family (father usually first, then mother, then children in order of birth)
    # :gender                       'Male', 'Female' for adults; 'Boy', 'Girl' for children
    # :first_name
    # :last_name
    # :suffix                       'Jr.', 'Sr.', 'II', etc.
    # :mobile_phone
    # :work_phone
    # :fax
    # :birthday
    # :email
    # :classes                      comma-separated list of class codes (used to link online groups with external source)
    # :mail_group                   single-character mailing code, e.g. 'M', 'A', 'P'
    # :anniversary
    # :member                       true/false
    # :staff                        true/false
    # :elder                        true/false
    # :deacon                       true/false
    # :can_sign_in                  true/false
    # :visible_to_everyone          true/false (overridden by individual user privacy settings)
    # :visible_on_printed_directory true/false
    # :full_access                  true/false
  end
  
  def each_family(updated_since)
    # for each family in external database, yield to the given block
    # a hash with the following keys (as symbols):
    
    # this method should only return families who've been updated since
    # the specified date; of course, you can ignore the updated_since
    # arg and simply return all families every time, but that's not
    # recommended unless your database is really small
    
    # :legacy_id         id from external database
    # :name              should be family name, e.g. 'Tim & Jennie Morgan'
    # :last_name         e.g. 'Morgan'
    # :suffix            'Jr.', 'Sr.', 'II', etc.
    # :address1
    # :address2
    # :city
    # :state             two-letter postal state, e.g. 'OK'
    # :zip
    # :home_phone
    # :email             family email, if applicable
    # :mail_group        single-character mailing code for family, e.g. 'M', 'A', 'P'
  end
end