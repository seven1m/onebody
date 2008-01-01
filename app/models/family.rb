# == Schema Information
# Schema version: 89
#
# Table name: families
#
#  id                 :integer       not null, primary key
#  legacy_id          :integer       
#  name               :string(255)   
#  last_name          :string(255)   
#  suffix             :string(25)    
#  address1           :string(255)   
#  address2           :string(255)   
#  city               :string(255)   
#  state              :string(2)     
#  zip                :string(10)    
#  home_phone         :integer       
#  email              :string(255)   
#  latitude           :float         
#  longitude          :float         
#  mail_group         :string(1)     
#  security_token     :string(25)    
#  share_address      :boolean       default(TRUE)
#  share_mobile_phone :boolean       
#  share_work_phone   :boolean       
#  share_fax          :boolean       
#  share_email        :boolean       
#  share_birthday     :boolean       default(TRUE)
#  share_anniversary  :boolean       default(TRUE)
#  updated_at         :datetime      
#  wall_enabled       :boolean       default(TRUE)
#  visible            :boolean       default(TRUE)
#  share_activity     :boolean       default(TRUE)
#

class Family < ActiveRecord::Base
  has_many :people, :order => 'sequence'
  
  acts_as_photo '/db/photos/families', PHOTO_SIZES
  acts_as_logger LogItem
  
  alias_method 'photo_without_logging=', 'photo='
  def photo=(p)
    LogItem.create :model_name => 'Family', :instance_id => id, :changes => {'photo' => (p ? 'changed' : 'removed')}, :person => Person.logged_in
    self.photo_without_logging = p
  end
  
  share_with :mobile_phone
  share_with :address
  share_with :anniversary
  
  def mapable?
    address1.to_s.any? and city.to_s.any? and state.to_s.any? and zip.to_s.any?
  end
  
  def mapable_address
    "#{address1}, #{address2.to_s.any? ? address2+', ' : ''}#{city}, #{state} #{zip}".gsub(/'/, "\\'")
  end
  
  def latitude
    return nil unless mapable?
    update_lat_lon unless read_attribute(:latitude) and read_attribute(:longitude)
    read_attribute :latitude
  end
  
  def longitude
    return nil unless mapable?
    update_lat_lon unless read_attribute(:latitude) and read_attribute(:longitude)
    read_attribute :longitude
  end
  
  def update_lat_lon
    return nil unless mapable?
    url = "http://api.local.yahoo.com/MapsService/V1/geocode?appid=#{SETTINGS['services']['yahoo']}&location=#{URI.escape(mapable_address)}"
    begin
      xml = URI(url).read
      result = REXML::Document.new(xml).elements['/ResultSet/Result']
      lat, lon = result.elements['Latitude'].text.to_f, result.elements['Longitude'].text.to_f
    rescue
      logger.error("Could not get latitude and longitude for address #{mapable_address} for family #{name}.")
    else
      update_attributes :latitude => lat, :longitude => lon
    end
  end

  def children_without_consent
    people.select { |p| !p.consent_or_13? }
  end
  
  def visible_people
    people.find(:all).select { |p| Person.logged_in.admin?(:view_hidden_profiles) or p.visible? }
  end
end
