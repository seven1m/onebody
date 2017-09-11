class Attachment < ApplicationRecord
  include Concerns::FileImage

  include Authority::Abilities
  self.authorizer_name = 'AttachmentAuthorizer'

  belongs_to :message, optional: true
  belongs_to :group, optional: true

  scope :images, -> { where("file_content_type like 'image/%'") }
  scope :non_images, -> { where("file_content_type not like 'image/%'") }

  scope_by_site_id

  has_attached_file :file, PAPERCLIP_FILE_OPTIONS
  do_not_validate_attachment_file_type :file

  validates_attachment_size :file, less_than: PAPERCLIP_FILE_MAX_SIZE

  def visible_to?(person)
    (message && person.can_read?(message))
  end

  def human_name
    name.split('.').first.humanize
  end

  class << self
    def create_from_file(attributes)
      file = attributes[:file]
      attributes[:name] = File.split(file.original_filename).last
      attributes[:content_type] = file.content_type
      create(attributes).tap do |attachment|
        if attachment.valid?
          attachment.file = file
          attachment.errors.add(:base, 'File could not be saved.') unless attachment.file.exists?
        end
      end
    end
  end
end
