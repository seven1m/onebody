class Publication < ActiveRecord::Base
  belongs_to :person
  belongs_to :site

  scope_by_site_id

  attr_accessible :name, :description, :file

  has_attached_file :file, PAPERCLIP_FILE_OPTIONS
  acts_as_logger LogItem

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :site_id
  validates_attachment_size :file, :less_than => PAPERCLIP_FILE_MAX_SIZE

  def pseudo_file_name
    filename = name.scan(/[a-z0-9]/i).join
    filename = id.to_s if filename.empty?
    filename + '.' + file.path.split('.').last
  end

  after_create :create_as_stream_item

  def create_as_stream_item
    StreamItem.create!(
      :title           => name,
      :body            => description,
      :person_id       => person_id,
      :streamable_type => 'Publication',
      :streamable_id   => id,
      :created_at      => created_at
    )
  end

  after_destroy :delete_stream_items

  def delete_stream_items
    StreamItem.destroy_all(:streamable_type => 'Publication', :streamable_id => id)
  end
end
