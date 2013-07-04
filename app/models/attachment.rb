class Attachment < ActiveRecord::Base
  belongs_to :message
  belongs_to :group
  belongs_to :site

  scope_by_site_id

  has_attached_file :file, PAPERCLIP_FILE_OPTIONS

  validates_attachment_size :file, less_than: PAPERCLIP_FILE_MAX_SIZE

  def visible_to?(person)
    (message and person.can_see?(message))
  end

  def human_name
    name.split('.').first.humanize
  end

  def image
    @img ||= unless @img == false
      if `identify -format "%m/%b/%w/%h" #{self.file.path}` =~ %r{(.+)/(.+)B/(\d+)/(\d+)}
        @img = {
          'format' => $1,
          'size'   => $2.to_i,
          'width'  => $3.to_i,
          'height' => $4.to_i
        }
      else
        @img = false
      end
    end
  end

  def image?
    image and %w(JPEG PNG GIF).include?(image['format'])
  end

  def width
    image? and image['width']
  end

  def height
    image? and image['height']
  end

  class << self
    def create_from_file(attributes)
      file = attributes[:file]
      attributes.merge!(name: File.split(file.original_filename).last, content_type: file.content_type)
      create(attributes).tap do |attachment|
        if attachment.valid?
          attachment.file = file
          attachment.errors.add(:base, 'File could not be saved.') unless attachment.file.exists?
        end
      end
    end
  end
end
