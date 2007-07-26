# This class doesn't do much yet except to serve as a template for your connector.
# See coms.rb for an example

class ExternalDataConnector
  
  def logger; RAILS_DEFAULT_LOGGER; end
  
  def initialize
    # do your database setup here
  end

  def each_person
    # for each person in external database, yield to the given block
    # a hash with the following keys (as symbols):
    
    # :legacy_id                    id from external database
    # :family_id                    (will be legacy_id on families table)
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
  
  def family_by_id(id)
    # for the specified family (legacy) id, return
    # a hash with the following keys (as symbols):
    
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