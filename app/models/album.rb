class Album < ActiveRecord::Base
  belongs_to :group
  belongs_to :person, include: :family, conditions: ['people.visible = ? and families.visible = ?', true, true]
  belongs_to :site
  has_many :pictures, dependent: :delete_all

  scope_by_site_id

  validates_presence_of :name
  validates_uniqueness_of :name, scope: [:site_id, :person_id]

  def cover
    @cover ||= pictures.find_by_cover(true)
    @cover ||= pictures.first
  end

  after_destroy :delete_stream_items

  def delete_stream_items
    StreamItem.destroy_all(streamable_type: 'Album', streamable_id: id)
  end
end
