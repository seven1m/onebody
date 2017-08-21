class Comment < ApplicationRecord
  include Authority::Abilities
  self.authorizer_name = 'CommentAuthorizer'

  belongs_to :person
  belongs_to :site
  belongs_to :commentable, polymorphic: true

  scope_by_site_id

  validates :text, length: { minimum: 4 }

  def name
    "Comment on #{commentable ? commentable.name : '?'}"
  end

  after_create :update_stream_items_on_create

  def update_stream_items_on_create
    find_all_associated_stream_items.each do |stream_item|
      next if stream_item.streamable_type == 'Album' && !Array(stream_item.context['picture_ids']).detect { |pic| pic.first == commentable.id }
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
    return [] unless commentable
    streamable_type = commentable_type
    streamable_id   = commentable.id
    if streamable_type == 'Picture'
      streamable_type = 'Album'
      streamable_id   = commentable.album_id
    end
    StreamItem.where(streamable_type: streamable_type, streamable_id: streamable_id).to_a
  end
end
