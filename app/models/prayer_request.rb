class PrayerRequest < ActiveRecord::Base
  include Authority::Abilities
  self.authorizer_name = 'PrayerRequestAuthorizer'

  belongs_to :group
  belongs_to :person
  belongs_to :site

  scope_by_site_id

  validates_presence_of :request, :group_id, :person_id

  self.skip_time_zone_conversion_for_attributes = [:answered_at]

  def name
    group_name = group.try(:name) || '?'
    I18n.t('prayer_requests.name', group: group_name)
  end

  def body
    request
  end

  def answered_at=(d)
    self[:answered_at] = d.respond_to?(:strftime) ? d : Date.parse_in_locale(d.to_s)
  end

  def streamable?
    person ? true : false
  end

  after_create :create_as_stream_item

  def create_as_stream_item
    return unless streamable?
    StreamItem.create!(
      title:           name,
      body:            body,
      person_id:       person_id,
      group_id:        group_id,
      streamable_type: 'PrayerRequest',
      streamable_id:   id,
      created_at:      created_at,
      shared:          !!group
    )
  end

  before_update :update_stream_items

  def update_stream_items
    return unless streamable?
    StreamItem.where(streamable_type: 'PrayerRequest', streamable_id: id).each do |stream_item|
      stream_item.body = body
      stream_item.created_at = updated_at if answer_changed?
      stream_item.save
    end
  end

  after_destroy :delete_stream_items

  def delete_stream_items
    StreamItem.destroy_all(streamable_type: 'PrayerRequest', streamable_id: id)
  end

  def send_group_email
    group.people.each do |person|
      Notifier.prayer_request(self, group, person).deliver_later
    end
  end
end
