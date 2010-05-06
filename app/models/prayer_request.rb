# == Schema Information
#
# Table name: prayer_requests
#
#  id          :integer       not null, primary key
#  group_id    :integer
#  person_id   :integer
#  request     :text
#  answer      :text
#  answered_at :datetime
#  created_at  :datetime
#  updated_at  :datetime
#  site_id     :integer
#

class PrayerRequest < ActiveRecord::Base
  belongs_to :group
  belongs_to :person
  belongs_to :site

  scope_by_site_id

  attr_accessible :request, :answer, :answered_at

  acts_as_logger LogItem

  validates_presence_of :request, :group_id, :person_id

  def name; "Prayer Request in #{group.name rescue '?'}"; end

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
      :body            => body,
      :person_id       => person_id,
      :group_id        => group_id,
      :streamable_type => 'PrayerRequest',
      :streamable_id   => id,
      :created_at      => created_at,
      :shared          => person.share_activity?
    )
  end

  after_update :update_stream_items

  def update_stream_items
    return unless streamable?
    StreamItem.find_all_by_streamable_type_and_streamable_id('PrayerRequest', id).each do |stream_item|
      stream_item.body  = body
      stream_item.save
    end
  end

  after_destroy :delete_stream_items

  def delete_stream_items
    StreamItem.destroy_all(:streamable_type => 'PrayerRequest', :streamable_id => id)
  end
end
