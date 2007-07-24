# This class doesn't do anything yet except to serve as a template for your connector.

class ExternalDataConnector
  
  def initialize
    # do your database setup here
  end

  def each_person
    # for each person in external database, yield to the given block
    # a hash or object with the following keys/attributes:
    
    # legacy_id                    id from external database
    # family_id                    (will be legacy_id on families table)
    # sequence                     order of person in family (father usually first, then mother, then children in order of birth)
    # gender                       'Male', 'Female' for adults; 'Boy', 'Girl' for children
    # first_name
    # last_name
    # suffix                       'Jr.', 'Sr.', 'II', etc.
    # mobile_phone
    # work_phone
    # fax
    # birthday
    # email
    # classes                      comma-separated list of class codes (used to link online groups with external source)
    # mail_group                   single-character mailing code, e.g. 'M', 'A', 'P'
    # anniversary
    # member                       true/false
    # staff                        true/false
    # elder                        true/false
    # deacon                       true/false
    # can_sign_in                  true/false
    # visible_to_everyone          true/false
    # visible_on_printed_directory true/false
    # full_access                  true/false
  end
  
  def each_family
    # for each family in external database, yield to the given block
    # a hash or object with the following keys/attributes:
    
    # legacy_id         id from external database
    # name              should be family name, e.g. 'Tim & Jennie Morgan'
    # last_name         e.g. 'Morgan'
    # suffix            'Jr.', 'Sr.', 'II', etc.
    # address1
    # address2
    # city
    # state             two-letter postal state, e.g. 'OK'
    # zip
    # home_phone
    # email             family email, if applicable
    # mail_group        single-character mailing code for family, e.g. 'M', 'A', 'P'
  end
  
  
end