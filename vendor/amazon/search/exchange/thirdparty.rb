# $Id: thirdparty.rb,v 1.16 2006/08/03 13:40:35 ianmacd Exp $

module Amazon
  module Search
    module Exchange

      # This module provides functionality for retrieving information on
      # Amazon third-party products.
      #
      module ThirdParty

	class Request < Amazon::Search::Request


	  # Exception class for bad offer status types.
	  #
	  class OfferStatusError < StandardError; end


	  # Returns an Array of valid offer status types, such as:
	  #
	  # *open*, *closed*
	  #
	  def ThirdParty.offer_status_types
	    %w[open closed]
	  end


	  # Search Amazon third-party sellers by ID and return an
	  # Amazon::Search::Exchange::ThirdParty::Response. If a block is
	  # supplied, that Response's @products, which is an Array of
	  # Amazon::Exchange::Product objects, will be passed to the block.
	  #
	  def seller_search(seller_id, weight=HEAVY, offer_status='open',
			    page=1, &block)
	    
	    # this search type not available for international sites
	    unless @locale == 'us'
	      raise LocaleError, "search type invalid in '#{@locale}' locale"
	    end

	    url = AWS_PREFIX + "?t=%s&SellerSearch=%s&f=xml&type=%s" +
		  "&dev-t=%s&page=%s"

	    type = WEIGHT[weight]

	    if ThirdParty.offer_status_types.include? offer_status
	      url << "&offerstatus=" << offer_status
	    else
	      raise StatusError, "'offer_status' must be one of %s" %
				 ThirdParty.offer_status_types.join(', ')
	    end

	    search(url % [@id, seller_id, type, @token, page], &block)
	  end

	end


	class Response < Amazon::Search::Exchange::Response

	  attr_reader :seller_nickname, :store_id,
		      :store_name, :open_listings

	  # Parse an Amazon::Search::Exchange::ThirdParty::Request and return
	  # an Amazon::Search::Exchange::ThirdParty::Response.
	  #
	  def parse
	    
	    doc = REXML::Document.new(self).elements['SellerSearch']
	    detail_node = doc.elements['SellerSearchDetails']

	    # populate args from top of doc
	    get_args(doc, detail_node)

	    doc = detail_node
	      
	    begin
	      @seller_nickname = doc.elements['SellerNickname'].text
	      @store_id = doc.elements['StoreId'].text
	      @store_name = doc.elements['StoreName'].text
	      @open_listings = doc.elements['NumberOfOpenListings'].text.to_i
	    rescue NoMethodError
	      # Exchange searches seem to fail an awful lot of the time
	      raise Amazon::Search::Request::SearchError, self
	    end

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
