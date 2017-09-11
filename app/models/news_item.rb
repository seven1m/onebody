class NewsItem < ApplicationRecord
  include Authority::Abilities
  self.authorizer_name = 'NewsItemAuthorizer'

  belongs_to :person, optional: true
  has_many :comments, as: :commentable, dependent: :destroy

  validates :title, :body, presence: true

  scope_by_site_id

  scope :active, -> { where(active: true) }

  def name
    title
  end

  before_save :update_published_date

  def update_published_date
    self.published = Time.now if published.nil?
  end

  after_create :create_as_stream_item

  def create_as_stream_item
    StreamItem.create!(
      title:           title,
      body:            body,
      person_id:       person_id,
      context:         link.present? ? { 'original_url' => link } : {},
      streamable_type: 'NewsItem',
      streamable_id:   id,
      created_at:      published,
      shared:          true,
      is_public:       true
    )
  end

  after_update :update_stream_items

  def update_stream_items
    StreamItem.where(streamable_type: 'NewsItem', streamable_id: id).each do |stream_item|
      stream_item.title = title
      stream_item.body  = body
      stream_item.save
    end
  end

  after_destroy :delete_stream_items

  def delete_stream_items
    StreamItem.where(streamable_type: 'NewsItem', streamable_id: id).destroy_all
  end

  class << self
    def update_from_feed
      if raw_items = get_feed_items
        active_items = []
        raw_items.each do |raw_item|
          item = where(link: raw_item.url).first_or_initialize
          item.link      = raw_item.url
          item.title     = raw_item.title
          item.body      = raw_item.content || raw_item.summary
          item.published = raw_item.published
          item.active    = true
          item.source    = 'feed'
          item.save
          active_items << item
        end
        if active_items.any?
          where(source: 'feed').deactivate_all_except(active_items)
        end
      end
    end

    def get_feed_items
      url = Setting.get(:url, :news_feed)
      if url.present?
        feed = Feedjira::Feed.fetch_and_parse(url)
        feed.try(:entries) || []
      else
        []
      end
    end

    def deactivate_all_except(items)
      where('id not in (?)', items.map(&:id)).update_all('active = 0')
    end
  end
end
