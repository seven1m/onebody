# == Schema Information
# Schema version: 20080715223033
#
# Table name: attachments
#
#  id           :integer       not null, primary key
#  message_id   :integer       
#  name         :string(255)   
#  content_type :string(50)    
#  created_at   :datetime      
#  site_id      :integer       
#  page_id      :integer       
#

class Attachment < ActiveRecord::Base
  belongs_to :message
  belongs_to :page
  belongs_to :site
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  acts_as_file DB_ATTACHMENTS_PATH
  
  def visible_to?(person)
    (message and person.can_see?(message)) or page
  end
  
  def human_name
    name.split('.').first.humanize
  end
  
  def width
    size
    @width
  end
  
  def height
    size
    @height
  end
  
  def size
    unless @width or @height
      begin
        img = MiniMagick::Image.from_blob(File.read(self.file_path))
        @width  = img['width']
        @height = img['height']
      rescue
        @width = @height = 0
      end
    end
    [@width, @height]
  end
  
  class << self
    def create_from_file(attributes)
      file = attributes.delete(:file)
      attributes.merge!(:name => File.split(file.original_filename).last, :content_type => file.content_type)
      returning create(attributes) do |attachment|
        if attachment.valid?
          attachment.file = file
          attachment.errors.add_to_base('File could not be saved.') unless attachment.has_file?
        end
      end
    end
  end
end
