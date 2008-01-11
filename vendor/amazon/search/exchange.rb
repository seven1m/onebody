# $Id: exchange.rb,v 1.16 2004/03/15 03:02:17 ianmacd Exp $

module Amazon
  module Search
    module Exchange

      class Request < Amazon::Search::Request
	
	# Perform an Exchange search and return an
	# Amazon::Search::Exchange::Response. If a block is given, that
	# Response's @products, which is an Array of Amazon::Exchange::Product
	# objects, will be passed to the block.
	# 
	def search(exchange_id, weight=HEAVY, &block)

	  # this search type not available for international sites
	  unless @locale == 'us'
	    raise LocaleError, "search type invalid in '#{@locale}' locale"
	  end

	  url = AWS_PREFIX + "?t=%s&ExchangeSearch=%s&f=xml&type=%s&dev-t=%s"

	  type = WEIGHT[weight]

	  super(url % [@id, exchange_id, type, @token], &block)
	end

      end
 

      class Response < Amazon::Search::Response

	# Parse an Amazon::Search::Exchange::Request and populate @products
	# with an Array of Amazon::Exchange::Product objects.
	#
	def parse
	  @products = []

	  if @stream.nil?
	    doc = REXML::Document.new(self).elements['ExchangeSearch']

	    # populate args from top of doc
	    get_args(doc)
	  else
	    doc = @stream
	  end

	  doc.elements.each("ListingProductDetails") do |detail|

	    product = Amazon::Exchange::Product.new

	    detail.elements.each do |property|
	      value = property.text

	      # perform any necessary conversions
	      if property.name =~ /Quantity/
		value = value.to_i
	      elsif property.name =~ /Rating/
		value = value.to_f
	      end

	      # normalise instance variable's name
	      iv = uncamelise(property.name)
	      product.instance_variable_set("@#{iv}".to_sym, value)
	    end

	    @products << product

	  end

	  self

	end
	private :parse

      end

    end
  end
end
