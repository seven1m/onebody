class DocumentFolder < ApplicationRecord
  include Authority::Abilities
  self.authorizer_name = 'DocumentFolderAuthorizer'

  belongs_to :folder, class_name: 'DocumentFolder', foreign_key: :folder_id, touch: true
  has_many :folders, class_name: 'DocumentFolder', foreign_key: :folder_id, dependent: :destroy
  has_many :documents, foreign_key: :folder_id, dependent: :destroy
  has_many :document_folder_groups, dependent: :destroy
  has_many :groups, through: :document_folder_groups

  scope :top,    -> { where(folder_id: nil) }
  scope :active, -> { where(hidden: false)  }
  scope :hidden, -> { where(hidden: true) }

  scope :restricted, -> {
    joins('left join document_folder_groups dfg on dfg.document_folder_id = document_folders.id')
      .where('dfg.id is not null')
  }

  scope :open, -> {
    joins('left join document_folder_groups dfg on dfg.document_folder_id = document_folders.id')
      .where('dfg.id is null')
  }

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
    if YAML.dump(parent_folder_ids).size > 1000
      errors.add(:parent_folder_ids, :too_long)
    end
  end

  serialize :parent_folder_ids, Array

  def parent_folders
    DocumentFolder.find(parent_folder_ids).sort_by { |f| parent_folder_ids.index(f.id) }
  end

  def all_group_ids
    (group_ids + parent_folders.flat_map(&:group_ids)).uniq
  end

  def all_groups
    Group.where(id: all_group_ids)
  end

  def restricted?
    group_ids.any?
  end

  def hidden_at_all?
    hidden? || parent_folders.any?(&:hidden?)
  end

  def item_count
    folders.count + documents.count
  end

  before_save do
    parents = []
    folder = self
    while (folder = folder.folder)
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
