class PrayerRequest < ActiveRecord::Base

  include Authority::Abilities
  self.authorizer_name = 'PrayerRequestAuthorizer'

  belongs_to :group
  belongs_to :person
  belongs_to :site

  scope_by_site_id

  validates_presence_of :request, :group_id, :person_id

  def name
    group_name = group.name rescue '?'
    I18n.t('prayer.name', group_name: group_name)
  end

  def body
    html = "#{request}"
    html << "<br/><strong>Answered #{answered_at ? answered_at.to_time.to_s(:date) : nil}:</strong> #{answer}" if answer.to_s.any?
    html
  end

  def streamable?
    person ? true : false
  end

  after_create :create_as_stream_item

  def create_as_stream_item
    return unless streamable?
    StreamItem.create!(
      body:            body,
      person_id:       person_id,
      group_id:        group_id,
      streamable_type: 'PrayerRequest',
      streamable_id:   id,
      created_at:      created_at,
      shared:          person.share_activity?
    )
  end

  after_update :update_stream_items

  def update_stream_items
    return unless streamable?
    StreamItem.where(streamable_type: "PrayerRequest", streamable_id: id).each do |stream_item|
      stream_item.body  = body
      stream_item.save
    end
  end

  after_destroy :delete_stream_items

  def delete_stream_items
    StreamItem.destroy_all(streamable_type: 'PrayerRequest', streamable_id: id)
  end
end
