# == Schema Information
#
# Table name: pictures
#
#  id           :integer       not null, primary key
#  person_id    :integer
#  created_at   :datetime
#  cover        :boolean       not null
#  updated_at   :datetime
#  site_id      :integer
#  album_id     :integer
#  original_url :string(1000)
#

class Picture < ActiveRecord::Base
  belongs_to :album
  belongs_to :person
  belongs_to :site
  has_many :comments, :dependent => :destroy

  scope_by_site_id

  has_one_photo :path => "#{DB_PHOTO_PATH}/pictures", :sizes => PHOTO_SIZES
  acts_as_logger LogItem

  validates_presence_of :album_id

  def name
    "Picture #{id}#{album ? ' in Album ' + album.name : nil}"
  end

  after_create :create_as_stream_item

  def create_as_stream_item
    return unless person
    if last_stream_item = StreamItem.last(:conditions => ["person_id = ? and created_at <= ?", person_id, created_at], :order => 'created_at') \
      and last_stream_item.streamable == album
      last_stream_item.context['picture_ids'] << id
      last_stream_item.created_at = created_at
      last_stream_item.save!
    else
      StreamItem.create!(
        :title           => album.name,
        :context         => {'picture_ids' => [id]},
        :person_id       => person_id,
        :group_id        => album.group_id,
        :streamable_type => 'Album',
        :streamable_id   => album_id,
        :created_at      => created_at,
        :shared          => album.group_id || person.share_activity? ? true : false
      )
    end
  end

  after_destroy :update_or_delete_stream_items

  def update_or_delete_stream_items
    StreamItem.find_all_by_streamable_type_and_streamable_id('Album', album_id).each do |stream_item|
      stream_item.context['picture_ids'].delete(id)
      if stream_item.context['picture_ids'].any?
        stream_item.save!
      else
        stream_item.destroy
      end
    end
  end
end
