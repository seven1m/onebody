class Donortools::Persona < ActiveResource::Base
  
  SLEEP_BETWEEN_PUSHES = 0.25
  SYNC_AT_A_TIME = 5
  
  def update_phone_numbers(locals)
    # scenarios:
    # 1. ph exists remotely - do nothing
    # 2. ph slot exists remotely, but not the right number - update number in place
    # 3. ph slot does not exist remotely - add new slot with correct number
    # 4. ph slot exists that does not exist locally - remove slot
    # 5. ph slot is a duplicate
    locals.each do |local|
      if remote = phone_numbers.detect { |p| same_address_type(p, local) }
        remote.phone_number = local[:phone_number] # 1, 2
      else
        phone_numbers << local # 3
      end
    end
    phone_numbers.each do |remote|
      unless locals.detect { |p| same_phone_number(p, remote) } and # 4
        phone_numbers.count { |p| same_phone_number(p, remote) } == 1 # 5
        remote.phone_number = nil
        remote.address_type_id = nil
      end
    end
  end
  
  def same_phone_number(p1, p2)
    ph1 = p1.respond_to?(:phone_number)    ? p1.phone_number    : p1[:phone_number]
    ph2 = p2.respond_to?(:phone_number)    ? p2.phone_number    : p2[:phone_number]
    ph1 == ph2 && same_address_type(p1, p2)
  end
  
  def same_address_type(p1, p2)
    at1 = p1.respond_to?(:address_type_id) ? p1.address_type_id : p1[:address_type_id]
    at2 = p2.respond_to?(:address_type_id) ? p2.address_type_id : p2[:address_type_id]
    at1 == at2
  end
  
  def admin_url
    "#{Setting.get('services', 'donor_tools_url').sub(/\/$/, '')}/personas/#{id}/donations"
  end
  
  class << self
    def can_sync?
      Setting.get(:services, :donor_tools_url).to_s.any? and
      Setting.get(:services, :donor_tools_api_email).to_s.any? and
      Setting.get(:services, :donor_tools_api_password).to_s.any?
    end
    
    def update_all
      return unless can_sync?
      setup_connection
      Person.unsynced_to_donortools(:all, :include => :family).each_slice(SYNC_AT_A_TIME) do |people|
        people.each do |person|
          next unless person.family and person.adult?
          person.update_donor
        end
        sleep SLEEP_BETWEEN_PUSHES
      end
    end
    
    def setup_connection
      Donortools::Donation.setup_connection
      self.site     = Setting.get(:services, :donor_tools_url)
      self.user     = Setting.get(:services, :donor_tools_api_email)
      self.password = Setting.get(:services, :donor_tools_api_password)
      true
    end
    
    def admin_url
      Setting.get('services', 'donor_tools_url').sub(/\/$/, '') + '/admin'
    end
  end
end