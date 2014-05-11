class Comment < ActiveRecord::Base

  include Authority::Abilities
  self.authorizer_name = 'CommentAuthorizer'

  belongs_to :person
  belongs_to :site

  # TODO: use polymorphism
  belongs_to :verse
  belongs_to :note
  belongs_to :picture

  scope_by_site_id

  def on
    verse || note || picture
  end

  def name
    "Comment on #{on ? on.name : '?'}"
  end

  after_create :update_stream_items_on_create

  def update_stream_items_on_create
    find_all_associated_stream_items.each do |stream_item|
      next if stream_item.streamable_type == 'Album' and not Array(stream_item.context['picture_ids']).detect { |pic| pic.first == on.id }
      stream_item.context['comments'] ||= []
      stream_item.context['comments'] << {
        'id'         => id,
        'person_id'  => person.id,
        'text'       => text,
        'created_at' => created_at
      }
      stream_item.save!
    end
  end

  after_destroy :update_stream_items_on_destroy

  def update_stream_items_on_destroy
    find_all_associated_stream_items.each do |stream_item|
      stream_item.context['comments'] ||= []
      stream_item.context['comments'].reject! { |c| c['id'] == id }
      stream_item.save!
    end
  end

  def find_all_associated_stream_items
    return [] unless on
    streamable_type = on.class.name
    streamable_id   = on.id
    if streamable_type == 'Picture'
      streamable_type = 'Album'
      streamable_id   = on.album_id
    end
    StreamItem.where(streamable_type: streamable_type, streamable_id: streamable_id).to_a
  end
end
