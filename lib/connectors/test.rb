# Test Connector
# This connector is only used to test the sync/connector system.

require File.dirname(__FILE__) + '/base'

class TestConnector < ExternalDataConnector
  def initialize
    @people = YAML::load(File.open(File.join(File.dirname(__FILE__), '/../../test/fixtures/people.yml')))
    @families = YAML::load(File.open(File.join(File.dirname(__FILE__), '/../../test/fixtures/families.yml')))
  end
  
  def people_ids
    @people.map { |p| p[:id] }
  end
  
  def family_ids
    @families.map { |f| f[:id] }
  end

  def each_person(updated_since)
    @people.each do |person|
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
    @families.each do |family|
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