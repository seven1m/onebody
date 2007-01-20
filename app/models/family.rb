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
    url = "http://api.local.yahoo.com/MapsService/V1/geocode?appid=#{YAHOO_APP_ID}&location=#{URI.escape(mapable_address)}"
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

  def name
    if f = NAME_CONVERSIONS[:families][id] and n = f[:name]
      n
    else
      read_attribute(:name)
    end
  end

  def last_name
    if f = NAME_CONVERSIONS[:families][id] and n = f[:last_name]
      n
    else
      read_attribute(:last_name)
    end
  end
end
