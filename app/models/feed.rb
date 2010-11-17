class Feed < ActiveRecord::Base
  belongs_to :person

  scope_by_site_id

  attr_accessible :name, :url

  validates_presence_of :person_id, :url, :name
  validates_uniqueness_of :name, :scope => [:site_id, :person_id]
  validates_uniqueness_of :url, :scope => [:site_id, :person_id]
  validates_format_of :url, :with => /^https?\:\/\/.+/

  before_save :transform_url

  def transform_url
    self.url = self.class.transform_url(url)
  end

  IMPORT_LIMIT = 5

  after_create :import_content

  def import_content
    return if Rails.env.test?
    begin
      feed = Feedzirra::Feed.fetch_and_parse(url)
      feed.entries
    rescue
      increment!(:error_count)
    else
      if feed and feed.entries.any?
        if feed.entries[0].url != last_url # otherwise, feed is up to date
          feed.entries[0...IMPORT_LIMIT].reverse.each do |entry|
            if url.include?('flickr.com')
              import_picture(entry)
            else
              import_note(entry)
            end
          end
          update_attribute :last_url, feed.entries[0].url
          # this is called from daemon/cron, so the view has no idea to clear the cache
          ActionController::Base.cache_store.delete_matched(%r{views/people/#{person_id}_})
        end
      else
        increment!(:error_count)
      end
    end
  end

  def import_note(entry)
    unless Note.exists?(['original_url = ? and person_id = ?', entry.url, person_id])
      body = entry.content || entry.summary
      if url.include?('twitter.com') and url =~ /screen_name=(.+)/
        username = $1
        body.sub!(/^#{username}:\s/, '')
      elsif url.include?('facebook.com')
        body = entry.title
      end
      note = person.notes.build
      note.title = url.include?('facebook.com') || url.include?('twitter.com') ? nil : entry.title
      note.body = body
      note.created_at = entry.published
      note.original_url = entry.url
      note.save
    end
  end

  def import_picture(entry)
    unless Picture.exists?(['original_url = ? and person_id = ?', entry.url, person_id])
      album = person.albums.find_or_create_by_name('Flickr') do |a|
        a.description = 'Photos from my Flickr account.'
        a.is_public = false
      end
      picture = person.pictures.create(
        :album_id     => album.id,
        :original_url => entry.url,
        :created_at   => entry.published
      )
      if entry.content =~ /<img src="([^"]+_m\.jpg)/
        url = $1.sub(/_m\.jpg$/, '_b.jpg') # "big" size
        res = Net::HTTP.get_response(URI.parse(url))
        if !res.is_a?(Net::HTTPOK)
          url = url.sub(/_b\.jpg$/, '.jpg') # try the original size
          res = Net::HTTP.get_response(URI.parse(url))
        end
        if res.is_a?(Net::HTTPOK)
          picture.photo = StringIO.new(res.body)
          unless picture.photo.exists?
            picture.destroy
          end
        else
          picture.destroy
        end
      else
        picture.destroy
      end
    end
  end

  def self.import_all
    Feed.all.each do |feed|
      feed.import_content
    end
  end

  def self.transform_url(url)
    url = url.to_s
    url = 'http://' + url unless url =~ /^https?:\/\//
    if url.include?('facebook.com')
      url.sub(/notifications\.php/, 'status.php')
    elsif url.include?('flickr.com') and open(url).read =~ /<link\s+rel="alternate"\s+type="application\/atom\+xml".+?href="([^"]+)">/
      $1
    else
      url
    end
  end
end
