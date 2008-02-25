# == Schema Information
# Schema version: 1
#
# Table name: updates
#
#  id               :integer       not null, primary key
#  person_id        :integer       
#  first_name       :string(255)   
#  last_name        :string(255)   
#  home_phone       :integer       
#  mobile_phone     :integer       
#  work_phone       :integer       
#  fax              :integer       
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
  belongs_to :person
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', 'Site.current.id'
  
  def do!
    raise 'Unauthorized' unless Person.logged_in.admin?(:manage_updates)
    %w(first_name last_name suffix gender mobile_phone work_phone fax).each do |attribute|
      person[attribute] = self[attribute] unless self[attribute].nil?
    end
    # I know this is ugly... a date with year 1800 means to blank out the attribute (because nil means no update)
    %w(birthday anniversary).each do |attribute|
      unless self[attribute].nil?
        person[attribute] = self[attribute].to_s(:date) =~ /1800/ ? nil : self[attribute]
      end
    end
    if person.save
      %w(home_phone address1 address2 city state zip family_name family_last_name).each do |attribute|
        person.family[attribute.gsub(/^family_/, '')] = self[attribute] unless self[attribute].nil?
      end
      person.family.save
    else 
      false
    end
  end
  
  def self.create_from_params(params, person)
    # turn formatted phone numbers into digits only
    %w(mobile_phone work_phone fax).each do |a|
      params[:person][a.to_sym] = params[:person][a.to_sym].digits_only if params[:person][a.to_sym]
    end
    params[:family][:home_phone] = params[:family][:home_phone].digits_only if params[:family][:home_phone]
    # keep only values that have changed from the originals
    family_updates = keep_changes(params[:family], person.family)
    family_updates[:family_name] = family_updates.delete(:name)
    family_updates[:family_last_name] = family_updates.delete(:last_name)
    updates = keep_changes(params[:person], person) + family_updates
    # date year 1800 means to blank the date
    updates[:birthday] = Date.new(1800, 1, 1) if updates.has_key?(:birthday) and updates[:birthday].nil?
    updates[:anniversary] = Date.new(1800, 1, 1) if updates.has_key?(:anniversary) and updates[:anniversary].nil?
    # save
    u = person.updates.create(updates)
    # send notification
    Notifier.deliver_profile_update(person, updates) if Setting.get(:contact, :send_updates_to)
    return u
  end
end

def keep_changes(updates, person)
  updates.delete_if do |key, value|
    value.to_s == person.send(key).to_s.gsub(/\s00:00:00$/, '')
  end
end
