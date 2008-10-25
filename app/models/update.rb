# == Schema Information
#
# Table name: updates
#
#  id               :integer       not null, primary key
#  person_id        :integer       
#  first_name       :string(255)   
#  last_name        :string(255)   
#  home_phone       :string(25)    
#  mobile_phone     :string(25)    
#  work_phone       :string(25)    
#  fax              :string(25)    
#  address1         :string(255)   
#  address2         :string(255)   
#  city             :string(255)   
#  state            :string(2)     
#  zip              :string(10)    
#  birthday         :datetime      
#  anniversary      :datetime      
#  created_at       :datetime      
#  complete         :boolean       
#  suffix           :string(25)    
#  gender           :string(6)     
#  family_name      :string(255)   
#  family_last_name :string(255)   
#  site_id          :integer       
#

class Update < ActiveRecord::Base
  PERSON_ATTRIBUTES = %w(first_name last_name mobile_phone work_phone fax birthday anniversary suffix gender)
  FAMILY_ATTRIBUTES = %w(family_name family_last_name home_phone address1 address2 city state zip)
  
  belongs_to :person
  belongs_to :site
  
  attr_protected :person_id, :site_id, :complete
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  
  def do!
    raise 'Unauthorized' unless Person.logged_in.admin?(:manage_updates)
    returning (person.update_attributes(person_attributes) and person.family.update_attributes(family_attributes)) do |success|
      person.errors.full_messages.each        { |m| self.errors.add_to_base "Person: #{m}" }
      person.family.errors.full_messages.each { |m| self.errors.add_to_base "Family: #{m}" }
    end
  end
  
  def mobile_phone=(phone)
    write_attribute :mobile_phone, phone.to_s.digits_only
  end
  
  def work_phone=(phone)
    write_attribute :work_phone, phone.to_s.digits_only
  end
  
  def fax=(phone)
    write_attribute :fax, phone.to_s.digits_only
  end
  
  def home_phone=(phone)
    write_attribute :home_phone, phone.to_s.digits_only
  end
  
  def person_attributes
    self.attributes.reject do |key, val|
      !PERSON_ATTRIBUTES.include?(key)
    end
  end
  
  def person_attributes=(attributes)
    self.attributes = attributes
  end
  
  def family_attributes
    {
      :name      => self.family_name,
      :last_name => self.family_last_name,
    }.merge(self.attributes.reject { |k, v| !(FAMILY_ATTRIBUTES - %w(family_name family_last_name)).include?(k) })
  end
  
  def family_attributes=(attributes)
    attributes = attributes.clone
    self.family_name = attributes.delete(:name)
    self.family_last_name = attributes.delete(:last_name)
    self.attributes = attributes
  end
  
  def changes
    p = self.person
    p.attributes = person_attributes
    f = p.family
    f.attributes = family_attributes
    f_changes = f.changes.clone
    f_changes['family_name']      = f_changes.delete('name')      if f_changes['name']
    f_changes['family_last_name'] = f_changes.delete('last_name') if f_changes['last_name']
    p.changes.merge(f_changes)
  end
  
  def self.create_from_params(params, person)
    params = HashWithIndifferentAccess.new(params) unless params.is_a? HashWithIndifferentAccess
    returning person.updates.new do |update|
      update.person_attributes = params[:person].reject_blanks
      update.family_attributes = params[:family].reject_blanks
      update.save
      Notifier.deliver_profile_update(person, update.changes) if Setting.get(:contact, :send_updates_to)
    end
  end

end
