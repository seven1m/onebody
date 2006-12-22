class Song < ActiveRecord::Base
  
  belongs_to :person
  has_many :attachments
  has_and_belongs_to_many :tags
  
  validates_presence_of :title
  
  def amazon_asin=(asin)
    old_asin = amazon_asin
    write_attribute :amazon_asin, asin
    lookup if asin != old_asin
  end
  
  def lookup
    return if amazon_asin.to_s.empty?
    begin
      req = Amazon::Search::Request.new(AMAZON_ID)
      product = req.asin_search(amazon_asin).products.first
      #self.artists = product.artists.join(', ')
      #self.album = product.product_name
      self.image_small_url = product.image_url_small
      self.image_medium_url = product.image_url_medium
      self.image_large_url = product.image_url_large
      self.amazon_url = product.url
    rescue
      return false
    end
  end
  
  def google_url
    "http://www.google.com/musicsearch?q=#{URI.encode(album)}+#{URI.encode(artists)}"
  end
  
  def walmart_url
    "http://www.walmart.com/search/search-ng.do?search_query=#{URI.encode(album)}+#{URI.encode(artists)}"
  end
  
  def yahoo_url
    "http://search.music.yahoo.com/search/?m=all&p=#{URI.encode(album)}+#{URI.encode(artists)}"
  end
  
  def tag_string=(text)
    text.split.each do |tag_name|
      tag = Tag.find_or_create_by_name(tag_name.downcase)
      tags << tag if not tags.include? tag
    end
    tags
  end
  
  class << self
    def search(query)
      req = Amazon::Search::Request.new(AMAZON_ID)
      if query.is_a? String
        req.asin_search(query).products.first rescue nil
      else
        if query[:album].to_s.any?
          query_string = query[:album]
        elsif query[:artists].to_s.any?
          query_string = query[:artists]
        elsif query[:title].to_s.any?
          query_string = query[:title]
        end
        products = req.keyword_search(query_string, 'music').products rescue []
        products.select do |product|
          product.product_name.downcase.index(query[:album].to_s.downcase) and
          product.artists.join(', ').downcase.index(query[:artists].to_s.downcase) and
          product.tracks and product.tracks.join(' ').downcase.index(query[:title].to_s.downcase)
        end
      end
    end
  end
end
