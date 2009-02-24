# == Schema Information
#
# Table name: pictures
#
#  id         :integer       not null, primary key
#  person_id  :integer       
#  created_at :datetime      
#  cover      :boolean       not null
#  updated_at :datetime      
#  site_id    :integer       
#  album_id   :integer       
#

class Picture < ActiveRecord::Base
  belongs_to :album
  belongs_to :person
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  
  acts_as_photo "#{DB_PHOTO_PATH}/pictures", PHOTO_SIZES
  acts_as_logger LogItem
  
  def name
    "Picture #{id}#{album ? ' in Album ' + album.name : nil}"
  end
end
