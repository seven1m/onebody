class Album < ActiveRecord::Base
  include Authority::Abilities
  include Concerns::Ability
  self.authorizer_name = 'AlbumAuthorizer'

  belongs_to :owner, polymorphic: true
  belongs_to :site
  has_many :pictures, dependent: :destroy
  has_one :stream_item, as: :streamable, dependent: :delete

  scope_by_site_id

  validates :name, presence: true, uniqueness: { scope: %i(site_id owner_type owner_id) }
  validates :owner, presence: true

  after_update :update_stream_item

  def update_stream_item
    return if stream_item.nil?
    stream_item.title = name
    stream_item.is_public = is_public?
    stream_item.save
  end

  def cover
    pictures.order('cover desc, id').first
  end

  def cover=(picture)
    pictures.update_all(cover: false)
    pictures.find(picture.id).update_attributes!(cover: true)
  end

  def group
    owner.is_a?(Group) ? owner : nil
  end

  def person
    owner.is_a?(Person) ? owner : nil
  end
end
