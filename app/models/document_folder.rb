class DocumentFolder < ActiveRecord::Base

  belongs_to :folder, class_name: 'DocumentFolder', foreign_key: :folder_id, touch: true
  has_many :folders, class_name: 'DocumentFolder', foreign_key: :folder_id, dependent: :destroy
  has_many :documents, foreign_key: :folder_id, dependent: :destroy

  scope :top,    -> { where(folder_id: nil) }
  scope :active, -> { where(hidden: false)  }

  scope_by_site_id

  validates :name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 1000 }

  validate do
    if folder_id
      if folder_id == id
        errors.add(:folder_id, :invalid)
      elsif folder.parent_folders.map(&:id).include?(id)
        errors.add(:folder_id, :invalid)
      end
    end
    if parent_folder_ids.length > 25 # temp until I can figure out how to check length of serialized text is < 1000
      errors.add(:parent_folder_ids, :too_long)
    end
  end

  serialize :parent_folder_ids, Array

  def parent_folders
    parent_folder_ids.map { |id| DocumentFolder.find(id) }
  end

  def item_count
    folders.count + documents.count
  end

  before_save do
    parents = []
    folder = self
    while folder = folder.folder
      parents << folder
    end
    self.parent_folder_ids = parents.map(&:id)
    if parents.any?
      self.path = parents.reverse.map(&:name).join(' > ') + " > #{name}"
      self.path = '...' + path[-997..-1] if path.length > 1000
    else
      self.path = name
    end
  end

end
