# $Id: marketplace.rb,v 1.31 2006/08/03 16:35:30 ianmacd Exp $

module Amazon
  module Search
    module Exchange

      # This module provides functionality for interacting with Amazon
      # Marketplace.
      #
      module Marketplace

	class Request < Amazon::Search::Request

	  # Exception class for bad keyword search types.
	  #
	  class KeywordSearchError < StandardError; end

	  # Exception class for bad zip codes.
	  #
	  class ZipcodeError < StandardError; end

	  # Exception class for bad geo types.
	  #
	  class GeoError < StandardError; end

	  # Exception class for bad area IDs.
	  #
	  class AreaIdError < StandardError; end

	  # Exception class for bad sort types.
	  #
	  class SortError < Amazon::Search::Request::SortError; end

	  # Exception class for bad index types.
	  #
	  class IndexError < StandardError; end


	  # Returns an Array of valid keyword search types, such as:
	  #
	  # *title*, *titledesc*
	  #
	  def Marketplace.keyword_search_types
	    %w[title titledesc]
	  end

	  # Returns an Array of valid geo types, such as:
	  #
	  # <b>ship-to</b>, <b>ship-from</b>
	  #
	  def Marketplace.geo_types
	    %w[ship-to ship-from]
	  end

	  # Returns an Array of valid sort types, such as:
	  #
	  # <b>-startdate</b>, <b>startdate</b>, <b>+startdate</b>,
	  # <b>-enddate</b>, <b>enddate</b>, <b>-sku</b>, <b>sku</b>,
	  # <b>-quantity</b>, <b>quantity</b>, <b>-price</b>, <b>price</b>,
	  # <b>+price</b>, <b>-title</b>, <b>Title</b>
	  #
	  def Marketplace.sort_types
	    %w[-startdate startdate +startdate -enddate enddate -sku sku
	       -quantity quantity -price price +price -title Title]
	  end

	  # Returns an Array of valid index types, such as:
	  #
	  # *marketplace*, *zshops*
	  #
	  def Marketplace.index_types
	    %w[marketplace zshops]
	  end


	  # Search Amazon Marketplace by keyword and return an
	  # Amazon::Search::Exchange::Marketplace::Response. If a block is
	  # supplied, that Response's @products, which is an Array of
	  # Amazon::Exchange::Product objects, will be passed to the block.
	  #
	  def keyword_search(seller_id, keyword, weight=HEAVY,
			     keyword_search=nil, browse_id=nil, zipcode=nil,
			     area_id=nil, geo=nil, sort=nil, index=nil, &block)
	    
	    url = AWS_PREFIX + "?t=%s&MarketplaceSearch=keyword&f=xml" +
		  "&type=%s&dev-t=%s&keyword=%s&seller-id=%s"

	    type = WEIGHT[weight]
	    keyword = url_encode(keyword)

	    unless keyword_search.nil?
	      if keyword_search_types.include? keyword_search
		url << "&keyword-search=" << keyword_search
	      else
		raise KeywordSearchError,
		  "'keyword_search' must be one of %s" %
		    keyword_search_types.join(', ')
	      end
	    end

	    url << "&browse-id=" << browse_id unless browse_id.nil?

	    unless zipcode.nil?
	      if zipcode !~ /^\d{5}$/
		raise ZipcodeError, "'zipcode' must be 5 digits"
	      end
	      url << "&zipcode=" << zipcode
	    end

	    unless area_id.nil? && geo.nil?
	      if geo.nil?
		raise GeoError,
		  "'geo' must be specified in combination with 'area_id'"
	      elsif area_id.nil?
		raise AreaIdError,
		  "'area_id' must be specified in combination with 'geo'"
	      elsif area_id !~ /^4000\d\d\d$/
		raise AreaIdError, "area code not well formed"
	      elsif ! geo_types.include? geo
		raise GeoError, "'geo' must be one of %s" %
				geo_types.join(', ')
	      end

	      url << "&area-id=%s&geo=%s" % [area_id, geo]
	    end

	    unless index.nil?
	      if index_types.include? index
		url << "&index=" << index
	      else
		raise IndexError,
		  "'index' must be one of %s" % index_types.join(', ')
	      end
	    end

	    url = url % [@id, type, @token, keyword, seller_id]

	    unless sort.nil?
	      if sort_types.include? sort
		url << "&sort=" << sort
	      else
		raise SortError,
		  "'sort' must be one of %s" % sort_types.join(', ')
	      end
	    end

	    search(url, &block)
	  end


	  # Search Amazon Marketplace by listing ID and return an
	  # Amazon::Search::Exchange::Marketplace::Response. If a block is
	  # supplied, that Response's @products, which is an Array of
	  # Amazon::Exchange::Product objects, will be passed to the block.
	  #
	  def listing_search(seller_id, listing_id, weight=HEAVY, &block)
	    url = "/onca/xml3?t=%s&MarketplaceSearch=listing-id&f=xml" +
		  "&type=%s&dev-t=%s&listing-id=%s&seller-id=%s"
	    type = weight ? 'heavy' : 'lite'

	    search(url % [@id, type, @token, listing_id, seller_id], &block)
	  end

	end


	class Response < Amazon::Search::Exchange::Response

	  attr_reader :open_listings

	  # Parse an Amazon::Search::Exchange::Marketplace::Request and
	  # return an Amazon::Search::Exchange::Marketplace::Response.
	  #
	  def parse
	    doc = REXML::Document.new(self).elements['MarketplaceSearch']
	    detail_node = doc.elements['MarketplaceSearchDetails']

	    # populate args from top of doc
	    get_args(doc, detail_node)

	    doc = detail_node

	    # get the number of open listings for a Marketplace search
	    begin
	      @open_listings = doc.elements['NumberOfOpenListings'].text.to_i
	      raise "zero open listings returned" if @open_listings == 0
	    rescue NoMethodError
	      # Marketplace searches seem to often fail
	      raise SearchError, self
	    end

	    return nil if @open_listings == 0

	    @stream = doc.elements['ListingProductInfo']
	    super

	    self

	  end
	  private :parse

	end
	
      end
    end
  end
end
