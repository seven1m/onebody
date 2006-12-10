require 'digest/md5'
require 'csv'

class LegacyPerson < ActiveRecord::Base
  class << self
    def migrate_table
      Person.delete_all
      Family.delete_all
      total = count
      find(:all).each_with_index do |person, index|
        home_phone = person.phone.scan(/\d/).join('').to_i
        home_phone = nil if home_phone == 0
        mobile_phone = person.mobile_phone.scan(/\d/).join('').to_i
        mobile_phone = nil if mobile_phone == 0
        family = Family.find_or_create_by_name(person.family_name)
        family.legacy_id = person.family_id
        family.last_name = person.family_last_name
        family.address1 = person.address1
        family.address2 = person.address2
        family.city = person.city
        family.state = person.state
        family.zip = person.zip
        family.home_phone = home_phone
        family.email = person.family_email
        family.latitude = person.lat
        family.longitude = person.lon
        family.anniversary = person.anniversary
        family.save
        family.people.create(
          :legacy_id => person.id,
          :sequence => person.sequence,
          :gender => person.gender,
          :first_name => person.first_name,
          :last_name => person.last_name,
          :mobile_phone => mobile_phone,
          :birthday => person.birthday,
          :email => person.email,
          :classes => person.classes,
          :mail_group => person.mailgroup,
          :encrypted_password => person.encrypted_password
        )
        if index % 100 == 0
          puts "#{index} of #{total}"
        end
      end
      puts "#{total} of #{total}"
    end
    
    def migrate_photos
      Dir.new(File.join(RAILS_ROOT, 'db/photos/families')).each do |filename|
        puts filename
        begin
          family_name = find_by_photograph(filename).family_name
          family_id = Family.find_by_name(family_name).id
        rescue
          puts 'could not find family'
        else
          File.rename(
            File.join(RAILS_ROOT, 'db/photos/families', filename),
            File.join(RAILS_ROOT, 'db/photos/families', "#{family_id}.jpg")
          )
          puts "renamed #{filename} to #{family_id}.jpg"
        end
      end
    end
    
    def resize_photos
      Dir.new(File.join(RAILS_ROOT, 'db/photos/families')).to_a.each do |filename|
        unless filename =~ /\..+\.jpg$/
          puts filename
          begin
            family = Family.find filename.to_i
          rescue
            puts "could not find family #{filename.to_i}"
          else
            family.photo = File.open(family.photo_path)
            puts "photo #{filename} resized"
          end
        end
      end
    end
    
    def fake_family_mail_group_from_first_person # temporary
      Person.find_all_by_sequence(1).each do |person|
        person.family.update_attribute :mail_group, person.mail_group
      end
    end
    
    def move_suffix_from_last_name # temporary
      Person.find(:all, :conditions => ["last_name like '%%,%%'"]).each do |person|
        last_name, suffix = person.last_name.split(', ')
        person.update_attributes :last_name => last_name, :suffix => suffix
      end
      Family.find(:all, :conditions => ["last_name like '%%,%%'"]).each do |family|
        last_name, suffix = family.last_name.split(', ')
        family.update_attributes :last_name => last_name
      end
    end
    
    # actually goes with Person model, but oh well :-)
    def import_passwords(filename)
      CSV.open(filename, 'r').each do |id, email, password, status|
        if person = Person.find_by_legacy_id(id)
          person.password = password
          person.save_with_validation(false)
        end
      end
    end
  end
end
