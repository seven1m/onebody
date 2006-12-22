class Song < ActiveRecord::Base
  
  belongs_to :person
  
  def lookup
    return unless amazon_asin
    begin
      product = req.asin_search(amazon_asin).products.first
      artists = product.artists.join(', ')
      album = product.product_title
      image_small_url = product.image_url_small
      image_medium_url = product.image_url_medium
      image_large_url = product.image_url_large
      amazon_url = product.url
    rescue
      return false
    end
  end
  
  class << self
    def search(query)
      req = Amazon::Search::Request.new(AMAZON_ID)
      req.keyword_search(query, 'music').products rescue []
    end
  end
end
