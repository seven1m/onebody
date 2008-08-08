# == Schema Information
#
# Table name: remote_accounts
#
#  id           :integer       not null, primary key
#  site_id      :integer       
#  person_id    :integer       
#  account_type :string(25)    
#  username     :string(255)   
#  token        :string(500)   
#

class RemoteAccount < ActiveRecord::Base
  RemoteAccount::ACCOUNT_TYPES = %w(highrise)
  
  belongs_to :site
  belongs_to :person
  has_many :sync_instances, :dependent => :destroy
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  
  validates_presence_of :username, :token, :account_type
  validates_inclusion_of :account_type, :in => ACCOUNT_TYPES
  validates_uniqueness_of :account_type, :scope => :person_id
  
  def site_uri
    case self.account_type
    when 'highrise'
      "http://#{token}:X@#{username}.highrisehq.com/"
    else
      raise 'Unknown remote account type'
    end
  end
  
  def update_remote_person(person)
    case self.account_type
    when 'highrise'
      update_remote_person_in_highrise(person)
    else
      raise 'Unknown remote account type'
    end
  end
  
  def update_remote_person_in_highrise(person)
    Highrise::Base.site = self.site_uri
    # have we synced before?
    remote_person = nil
    if sync = self.sync_instances.find_by_person_id(person.id)
      begin
        remote_person = Highrise::Person.find(sync.remote_id)
      rescue ActiveResource::ResourceNotFound
        # oops, contact was deleted, start over
        sync.destroy; sync = nil
      end
    end
    remote_person = Highrise::Person.new unless remote_person
    remote_person.first_name = person.first_name
    remote_person.last_name = person.last_name
    remote_person.company_name = person.service_name if person.service_name.to_s.any?
    remote_person.save unless remote_person.defined? :contact_data
    remote_person.add_contact_data(:email_addresses, 'Other', :address => person.email)
    remote_person.add_contact_data(:phone_numbers, 'Mobile', :number => person.mobile_phone.to_s)
    remote_person.add_contact_data(:phone_numbers, 'Work', :number => person.work_phone.to_s)
    remote_person.add_contact_data(:phone_numbers, 'Fax', :number => person.fax.to_s)
    remote_person.add_contact_data(:phone_numbers, 'Home', :number => person.home_phone.to_s)
    remote_person.add_contact_data(:web_addresses, 'Other', :url => person.website)
    remote_person.add_contact_data(:addresses, 'Home', :street => person.address, :city => person.city, :state => person.state, :zip => person.zip)
    remote_person.save
    if sync
      sync.save # update timestamp
    else
      sync = self.sync_instances.create(
        :owner_id => self.person_id,
        :person_id => person.id,
        :remote_id => remote_person.id
      )
    end
  end
  
  def update_all_remote_people
    self.sync_instances.each { |s| s.update_remote_person }
  end
  
  def synced?(person)
    self.sync_instances.find_by_person_id(person.id)
  end
  
end

class Highrise::Person
  def add_contact_data(collection, location, fields)
    fields.stringify_keys!
    fields.merge!('location' => location)
    same = contact_data.send(collection).select do |item|
      if item.is_a?(Hash)
        false
      else
        cmp = item.attributes.dup.delete_if { |k, v| %w(id country).include? k }
        cmp == fields
      end
    end
    unless same.any?
      contact_data.send(collection) << fields
    end
  end
end
