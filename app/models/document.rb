class Document < ActiveRecord::Base
  include Authority::Abilities
  self.authorizer_name = 'DocumentAuthorizer'

  include Concerns::FileImage

  belongs_to :folder, class_name: 'DocumentFolder', foreign_key: :folder_id, touch: true

  scope :top, -> { where(folder_id: nil) }

  scope_by_site_id

  validates :name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 1000 }
  validates :file, presence: true

  has_attached_file :file, PAPERCLIP_FILE_OPTIONS
  do_not_validate_attachment_file_type :file

  validates_attachment_size :file, less_than: PAPERCLIP_FILE_MAX_SIZE

  def parent_folders
    return [] if folder.nil?
    [folder] + folder.parent_folders
  end

  def parent_folder_group_ids
    parent_folders.flat_map(&:group_ids).uniq
  end

  def parent_folder_groups
    Group.where(id: parent_folder_group_ids)
  end

  def restricted?
    parent_folder_group_ids.any?
  end

  def hidden?
    parent_folders.any?(&:hidden?)
  end
end
