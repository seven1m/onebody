class StreamItem < ActiveRecord::Base
  belongs_to :person
  belongs_to :site
  belongs_to :group
  belongs_to :streamable, polymorphic: true

  serialize :context, Hash

  scope_by_site_id

  def can_have_comments?
    %w(Verse Note Album).include?(streamable_type)
  end

  def self.shared_with(person)
    all \
      .order(created_at: :desc) \
      .includes(:person, :group) \
      .where(streamable_type: shared_streamable_types) \
      .where(shared: true) \
      .where(
        "(group_id in (:group_ids) or (group_id is null and person_id in (:friend_ids)) or person_id = :id or streamable_type = 'NewsItem')",
        group_ids:  person.groups.active.pluck(:id),
        friend_ids: person.all_friend_and_groupy_ids,
        id:         person.id
      )
  end

  def self.shared_streamable_types
    [].tap do |types|
      types << 'Message' # group posts (not personal messages)
      types << 'NewsItem' if Setting.get(:features, :news_page)
      types << 'Verse'    if Setting.get(:features, :verses)
      types << 'Album'    if Setting.get(:features, :pictures)
      types << 'Note'     if Setting.get(:features, :notes)
      types << 'PrayerRequest'
    end
  end
end
