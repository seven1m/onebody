class Picture < ApplicationRecord
  include Authority::Abilities
  include Concerns::Ability
  self.authorizer_name = 'PictureAuthorizer'

  belongs_to :album
  belongs_to :person, optional: true
  has_many :comments, as: :commentable, dependent: :destroy

  scope_by_site_id

  has_attached_file :photo, PAPERCLIP_PHOTO_OPTIONS

  validates_presence_of :album_id
  validates_attachment_size :photo, less_than: PAPERCLIP_PHOTO_MAX_SIZE
  validates_attachment_content_type :photo, content_type: PAPERCLIP_PHOTO_CONTENT_TYPES

  def name
    "Picture #{id}#{album ? ' in Album ' + album.name : nil}"
  end

  VALID_DEGREES = [90, -90, 180].freeze

  class ErrorRotatingPhoto < RuntimeError; end

  def rotate(degrees)
    unless VALID_DEGREES.include?(degrees)
      raise ErrorRotatingPhoto, 'Invalid degree value.'
    end
    tmp = Tempfile.new(['photo', File.extname(photo.path)])
    if (img = MiniMagick::Image.open(photo.path)) && img.valid?
      img.rotate(degrees)
      img.write(tmp.path)
      self.photo = tmp
      save!
      tmp.delete
      valid?
    else
      raise ErrorRotatingPhoto
    end
  end

  # return the next picture in this album
  # if this is the last picture in the album, return the first
  def next
    album.pictures.order(:id).where('id > ?', id).first ||
      album.pictures.order(:id).first
  end

  # return the previous picture in this album
  # if this is the first picture in the album, return the last
  def prev
    album.pictures.order(:id).where('id < ?', id).last ||
      album.pictures.order(:id).last
  end

  def photo_extension
    if filename = photo.try(:original_filename)
      File.extname(filename).sub(/^\.+/, '')
    end
  end

  after_create :create_as_stream_item

  def create_as_stream_item
    return unless person && (photo? || Rails.env.test?)
    if (last_stream_item = StreamItem.where(person_id: person_id).order('id').last) \
      && last_stream_item.streamable == album
      last_stream_item.context['picture_ids'] << [id, photo.fingerprint, photo_extension]
      last_stream_item.created_at = created_at
      last_stream_item.save!
    else
      StreamItem.create!(
        title:           album.name,
        context:         { 'picture_ids' => [[id, photo.fingerprint, photo_extension]] },
        person_id:       person_id,
        group_id:        album.owner_type === 'Group' ? album.owner_id : nil,
        streamable_type: 'Album',
        streamable_id:   album_id,
        created_at:      created_at,
        shared:          !!(album.group || person.share_activity?),
        is_public:       album.is_public?
      )
    end
  end

  after_update :update_stream_items

  def update_stream_items
    StreamItem.where(streamable_type: 'Album', streamable_id: album_id).each do |stream_item|
      stream_item.context['picture_ids'].each do |pic|
        if pic[0] == id
          pic[1] = photo.fingerprint
          pic[2] = photo_extension
        end
      end
      stream_item.save!
    end
  end

  after_destroy :delete_stream_items

  def delete_stream_items
    StreamItem.where(streamable_type: 'Album', streamable_id: album_id).each do |stream_item|
      stream_item.context['picture_ids'].reject! { |pic| pic == id || pic.first == id }
      if stream_item.context['picture_ids'].any?
        stream_item.save!
      else
        stream_item.destroy
      end
    end
  end

  # used by StreamItem to generate photo urls from a few details
  # without querying the actual Picture object
  def self.photo_url_from_parts(id, fingerprint, extension, style)
    PAPERCLIP_PHOTO_OPTIONS[:url].sub(/:rails_env/, Rails.env).sub(/:class/, 'pictures').sub(/:attachment/, 'photos').sub(/:id/, id.to_s).sub(/:style/, style.to_s).sub(/:fingerprint/, fingerprint).sub(/:extension/, extension)
  end
end
