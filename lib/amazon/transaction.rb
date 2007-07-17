# $Id: transaction.rb,v 1.9 2004/03/10 09:48:39 ianmacd Exp $
#

require 'amazon/search'

module Amazon

  # Load this library with:
  #
  #  require 'amazon/transaction'
  #
  # This class provides access to Amazon's Transaction Details API.
  #
  class Transaction < Amazon::Product

    # Amazon::Transaction::Item is used to store the unit price and total
    # price of a transaction item.
    #
    class Item # :nodoc:
      attr_accessor :unit_price, :total_price

      def initialize
	@unit_price = {}
	@total_price = {}
      end
    end


    # Amazon::Transaction::Error is an object used to store the data
    # pertaining to an error in the processing of an order ID.
    #
    class Error
      attr_accessor :order_id, :error_code, :error_message

      def initialize(order_id, error_code, error_message) # :nodoc:
	@order_id = order_id
	@error_code = error_code
	@error_message = error_message
      end
    end


    # This is the maximum number of order IDs that can be specified in
    # Amazon::Transaction::Request#get_details.
    #
    MAX_ORDER_IDS = 5

    attr_reader   :order_id, :seller_id, :condition,
		  :transaction_date, :transaction_epoch
    attr_accessor :total, :subtotal, :shipping, :tax, :promotion, :items,
		  :error

    # Amazon::Transaction
    #
    def initialize(order_id, seller_id=nil, condition=nil,
		   trans_date=nil, trans_epoch=nil) # :nodoc:

      @order_id = order_id
      @seller_id = seller_id
      @condition = condition
      @transaction_date = trans_date
      @transaction_epoch = trans_epoch
      @total = {}
      @subtotal = {}
      @shipping = {}
      @tax = {}
      @promotion = {}
      @items = []
      @error = nil
    end


    class Request < Amazon::Search::Request

      # This exception is raised when there is a problem with the number
      # of order IDs.
      #
      class OrderIDError < TermError; end

      # Retrieve a transaction order ID (_order_id_ may be an Array, or a
      # space or comma-separated string). This returns an Array of
      # Amazon::Transaction objects, passing them to a block, if given.
      #
      def get_details(order_id, &block)

	url = AWS_PREFIX + "?t=%s&dev-t=%s&TransactionDetails=ShortSummary" +
	      "&OrderId=%s&f=xml"

	order_id.gsub!(/ /, ',') if order_id.is_a? String
	order_id = order_id.join(',') if order_id.is_a? Array

	if order_id.count(',') >= MAX_ORDER_IDS
	  raise OrderIdError, "too many order IDs"
	end

	search(url % [@id, @token, order_id], &block)
      end


      # Perform the actual search.
      #
      def search(url, &block) # :nodoc:
	url << "&locale=" << @locale

	Amazon::dprintf("Fetching http://%s%s...\n", @conn.address, url)

	# get the page and return it
	response = Response.new(get_page(url))

	response.transactions.each(&block) if block_given?

	response
      end
      private :search

    end
  

    class Response < Amazon::Search::Response

      attr_reader :transactions

      # Parse an Amazon::Transaction::Request and return an
      # Amazon::Transaction::Response.
      #
      def parse

	doc = REXML::Document.new(self).elements['TransactionDetails']

	# populate @args with header data
	get_args(doc) if @args.empty?

	@transactions = []

	doc.elements.each('ShortSummaries/ShortSummary') do |summary|
	  begin
	    order_id = summary.elements['OrderId'].text
	    seller_id = summary.elements['SellerId'].text
	    condition = summary.elements['Condition'].text
	    date = summary.elements['TransactionDate'].text
	    epoch = summary.elements['TransactionDateEpoch'].text
	  
	    transaction = Transaction.new(order_id, seller_id, condition,
					  date, epoch)

	    summary.elements.each('Total/*') do |property|
	      transaction.total[property.name] = property.text
	    end

	    summary.elements.each('Subtotal/*') do |property|
	      transaction.subtotal[property.name] = property.text
	    end

	    summary.elements.each('Shipping/*') do |property|
	      transaction.shipping[property.name] = property.text
	    end

	    summary.elements.each('Tax/*') do |property|
	      transaction.tax[property.name] = property.text
	    end

	    summary.elements.each('Promotion/*') do |property|
	      transaction.promotion[property.name] = property.text
	    end

	    items = []
	    summary.elements.each('Items/Item') do |item|
	      item_nr = item.elements['ItemNumber'].text.to_i - 1
	      items[item_nr] = Amazon::Transaction::Item.new

	      item.elements.each('UnitPrice/*') do |property|
		items[item_nr].unit_price[property.name] = property.text
	      end

	      item.elements.each('TotalPrice/*') do |property|
		items[item_nr].total_price[property.name] = property.text
	      end

	      transaction.items = items
	    end

	  rescue NoMethodError
	    # some kind of error occurred
	    order_id = summary.elements['Error/OrderId'].text
	    error_code = summary.elements['Error/ErrorCode'].text
	    error_message = summary.elements['Error/ErrorMessage'].text

	    transaction = Transaction.new(order_id)
	    transaction.error =
	      Amazon::Transaction::Error.new(order_id, error_code,
					     error_message)
	  end

	  @transactions << transaction
	end

	self

      end
      private :parse

    end

  end
end
