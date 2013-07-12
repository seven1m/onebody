class Album < ActiveRecord::Base

  include Authority::Abilities
  include AbilityConcern
  self.authorizer_name = 'AlbumAuthorizer'

  belongs_to :owner, polymorphic: true
  belongs_to :site
  has_many :pictures, dependent: :delete_all

  scope_by_site_id

  validates_presence_of :name
  validates_uniqueness_of :name, scope: [:site_id, :owner_type, :owner_id]

  def remove_owner=(remove)
    if remove and Person.logged_in.admin?(:manage_pictures)
      self.owner = nil
      self.is_public = true
    end
  end

  def cover
    pictures.order('cover desc, id').first
  end

  def cover=(picture)
    pictures.update_all(cover: false)
    pictures.find(picture.id).update_attributes!(cover: true)
  end

  after_destroy :delete_stream_items

  def delete_stream_items
    StreamItem.destroy_all(streamable_type: 'Album', streamable_id: id)
  end

  def group
    Group === owner ? owner : nil
  end

  def person
    Person === owner ? owner : nil
  end
end
