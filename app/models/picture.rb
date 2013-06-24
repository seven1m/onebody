class Picture < ActiveRecord::Base
  belongs_to :album
  belongs_to :person
  belongs_to :site
  has_many :comments, :dependent => :destroy

  scope_by_site_id

  has_attached_file :photo, PAPERCLIP_PHOTO_OPTIONS

  validates_presence_of :album_id
  validates_attachment_size :photo, :less_than => PAPERCLIP_PHOTO_MAX_SIZE
  validates_attachment_content_type :photo, :content_type => PAPERCLIP_PHOTO_CONTENT_TYPES

  def name
    "Picture #{id}#{album ? ' in Album ' + album.name : nil}"
  end

  VALID_DEGREES = [90, -90, 180]

  class ErrorRotatingPhoto < RuntimeError; end

  def rotate(degrees)
    if !VALID_DEGREES.include?(degrees)
      raise ErrorRotatingPhoto.new('Invalid degree value.')
    end
    tmp = Tempfile.new(['photo', File.extname(photo.path)])
    size = `convert #{photo.path} -rotate #{degrees} #{tmp.path} && stat -c %s #{tmp.path}`
    if size.to_i > 0
      self.photo = tmp
      save!
      tmp.delete
      valid?
    else
      raise ErrorRotatingPhoto
    end
  end

  def photo_extension
    File.extname(photo.original_filename).sub(/^\.+/, '')
  end

  after_create :create_as_stream_item

  def create_as_stream_item
    return unless person
    if last_stream_item = StreamItem.last(:conditions => ["person_id = ? and created_at <= ?", person_id, created_at], :order => 'created_at') \
      and last_stream_item.streamable == album
      last_stream_item.context['picture_ids'] << [id, photo.fingerprint, photo_extension]
      last_stream_item.created_at = created_at
      last_stream_item.save!
    else
      StreamItem.create!(
        :title           => album.name,
        :context         => {'picture_ids' => [[id, photo.fingerprint, photo_extension]]},
        :person_id       => person_id,
        :group_id        => album.group_id,
        :streamable_type => 'Album',
        :streamable_id   => album_id,
        :created_at      => created_at,
        :shared          => album.group_id || person.share_activity? ? true : false
      )
    end
  end

  after_update :update_stream_items

  def update_stream_items
    StreamItem.find_all_by_streamable_type_and_streamable_id('Album', album_id).each do |stream_item|
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
    StreamItem.find_all_by_streamable_type_and_streamable_id('Album', album_id).each do |stream_item|
      stream_item.context['picture_ids'].reject! { |pic| pic == self.id or pic.first == self.id }
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
