class Attachment < ActiveRecord::Base

  include Authority::Abilities
  self.authorizer_name = 'AttachmentAuthorizer'

  belongs_to :message
  belongs_to :group
  belongs_to :site

  scope_by_site_id

  has_attached_file :file, PAPERCLIP_FILE_OPTIONS
  do_not_validate_attachment_file_type :file

  validates_attachment_size :file, less_than: PAPERCLIP_FILE_MAX_SIZE

  def visible_to?(person)
    (message and person.can_see?(message))
  end

  def human_name
    name.split('.').first.humanize
  end

  def image
    return @img unless @img.nil?
    if img = MiniMagick::Image.new(file.path) and img.valid?
      @img = img
    else
      @img = false
    end
  end

  def image?
    image and %w(JPEG PNG GIF).include?(image[:format])
  end

  def width
    image[:width] if image?
  end

  def height
    image[:height] if image?
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
