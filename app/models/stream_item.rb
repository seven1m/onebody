class StreamItem < ApplicationRecord
  belongs_to :person
  belongs_to :site
  belongs_to :group
  belongs_to :streamable, polymorphic: true
  belongs_to :stream_item_group, class_name: 'StreamItem'

  has_many :items,
           -> { order(created_at: :desc) },
           class_name: 'StreamItem',
           foreign_key: 'stream_item_group_id',
           dependent: :nullify

  scope :groups, -> { where(streamable_type: 'StreamItemGroup') }

  serialize :context, Hash

  scope_by_site_id

  def can_have_comments?
    %w(Verse Note Album).include?(streamable_type)
  end

  def self.shared_with(person)
    order(created_at: :desc)
      .includes(:person, :group)
      .where(streamable_type: shared_streamable_types)
      .where(shared: true)
      .where("(group_id is not null or streamable_type != 'Message')")
      .where(
        '(group_id in (:group_ids) or ' \
        '(group_id is null and person_id in (:friend_ids)) or ' \
        'person_id = :id or ' \
        "streamable_type in ('NewsItem', 'Site', 'Person') or " \
        'is_public = :true)',
        group_ids:  person.groups.active.pluck(:id),
        friend_ids: person.sharing_with_people.pluck(:id),
        id:         person.id,
        true:       true
      )
      .where("streamable_type != 'Person' or person_id != :id", id: person.id)
      .where(stream_item_group_id: nil)
  end

  def self.shared_streamable_types
    [].tap do |types|
      types << 'Message' # group posts (not personal messages)
      types << 'NewsItem' if Setting.get(:features, :news_page)
      types << 'Verse'    if Setting.get(:features, :verses)
      types << 'Album'    if Setting.get(:features, :pictures)
      types << 'Note'     if Setting.get(:features, :notes)
      types << 'Person'
      types << 'PrayerRequest'
      types << 'Site'
      types << 'StreamItemGroup'
    end
  end
end
