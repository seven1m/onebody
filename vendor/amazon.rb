# $Id: amazon.rb,v 1.57 2006/08/09 20:07:39 ianmacd Exp $
# 
#:include: ../README.rdoc

module Amazon

  NAME	      = 'Ruby/Amazon'
  VERSION     = '0.9.2'
  USER_AGENT  = "%s %s" % [NAME, VERSION]

  SITE	      = { 'ca' => 'www.amazon.ca',
		  'de' => 'www.amazon.de',
		  'fr' => 'www.amazon.fr',
		  'jp' => 'www.amazon.co.jp',
		  'uk' => 'www.amazon.co.uk',
		  'us' => 'www.amazon.com'
  }

  # :stopdoc:
  DEFAULT_ID  = { 'ca' => 'caliban-20',
		  'de' => 'calibanorg0a-21',
		  'fr' => 'caliban08-21',
		  'jp' => 'calibanorg-20',
		  'uk' => 'caliban-21',
		  'us' => 'calibanorg-20'
  }
  # :startdoc:

  
  # Prints debugging messages and works like printf, except that it prints
  # only when Ruby is run with the -d switch.
  #
  def Amazon.dprintf(format, *args)
    $stderr.printf(format, *args) if $DEBUG
  end


  # Amazon::Product objects are returned by many of the basic forms of search
  # in Amazon::Search::Request.
  #
  class Product

    attr_reader :url  # :nodoc:

    #
    # This class holds product reviews.
    #
    class Review

      attr_reader :rating, :summary, :comment

      def initialize(rating, summary, comment)	# :nodoc:
	@rating = rating.to_i
	@summary = summary
	@comment = comment
      end

    end


    #
    # This class holds third party information related to offerings.
    #
    class ThirdPartyInfo

      attr_reader :offering_type, :seller_id, :seller_nickname, :exchange_id,
		  :offering_price, :condition, :seller_nickname,
		  :condition_type, :exchange_availability, :seller_country,
		  :seller_state, :ship_comments, :seller_rating

      def initialize  # :nodoc:
      end
    end


    #
    # This exception is raised when an attempt is made to read a product
    # attribute that doesn't exist.
    #
    #class AttributeError < StandardError; end


    # 
    # This alias makes the ability to determine a product's properties a
    # little more intuitive.
    #
    alias_method :properties, :instance_variables

    def initialize(url)	# :nodoc:
      @url = url
    end

    #
    # Displays a product in a human-readable format. Call without a parameter,
    # as the parameter is only for internal use.
    # 
    def to_s(first_detail='productname')
      string = ""

      # get all attributes, minus the leading '@'
      vars = self.instance_variables.sort.map {|v| v[1..-1]}

      # find the longest attribute name
      longest = vars.sort { |a,b| b.length <=> a.length }[0].length

      # put the product name at the front of the list, if we have one
      vars.unshift(first_detail) if vars.delete(first_detail)

      # display the product's details
      vars.each do |iv|
	value = self.instance_variable_get("@#{iv}").inspect
	string << "%-#{longest}s = %s\n" % [iv, value]
      end

      string

    end

    #
    # Converts an Amazon::Product to a Hash.
    #
    def to_h
      hash = {}
      self.properties.each do |property|
	key = property[1..-1]
	val = self.instance_variable_get(property)
	hash[key] = val
      end
      hash
    end

    # 
    # Fake the appearance of a product as a hash. _key_ should be any
    # attribute of the product, as returned by Amazon::Product#properties.
    #
    # E.g.
    #
    #  puts product['our_price'] => "$8.99"
    #  puts product[:our_price]  => "$8.99"
    #
    def [](key)
      self.instance_variable_get('@' + key.to_s)
    end

    #
    # Since we can't know in advance which attributes a product will
    # have, we construct a reader method dynamically for each attribute
    # the first time someone tries to read it. So, this method will only
    # be called a maximum of once per attribute for the whole class.
    #
    def method_missing(method)
      iv = '@' + method.id2name

      if instance_variables.include? iv
	Product.module_eval { attr_reader method }
	instance_variable_get iv
      elsif iv == '@catalogue'
	# Allow British English spelling of catalogue
	instance_variable_get '@catalog'
      else
	#raise AttributeError, "product has no #{iv}"
	nil
      end
    end

    private :method_missing

  end


  #
  # This class holds Amazon Seller profile data, as returned by the
  # Amazon::Search::Seller module.
  #
  class Seller < Product
    attr_reader :seller_nickname, :overall_feedback_rating, :nr_feedback,
		:store_id, :store_name, :feedback

    def initialize(nickname, rating, quantity, store_id,
		   store_name, feedback) # :nodoc:
      @seller_nickname = nickname
      @overall_feedback_rating = rating
      @nr_feedback = quantity
      @store_id = store_id
      @store_name = store_name
      @feedback = feedback
    end

    #
    # Convert a seller object to human-readable format.
    #
    def to_s
      super 'store_name'
    end

  end


  #
  # This class holds Amazon Seller feedback, as returned by the
  # Amazon::Search::Seller module.
  #
  class Feedback
    attr_reader :rating, :comments, :date, :rater

    def initialize(rating, comments, date, rater) # :nodoc:
      @rating = rating.to_i
      @comments = comments
      @date = date
      @rater = rater
    end

  end


  module Exchange   # :nodoc:
 
    # Amazon::Exchange::Product objects are returned by
    # Amazon::Search::Exchange searches and those of its sub-classes.
    #
    class Product < Amazon::Product
      def initialize  # :nodoc:
      end
    end

  end


  # This class holds Amazon::ProductLine objects returned by the
  # Amazon::Search::Blended module.
  #
  class ProductLine < Amazon::Product

    attr_reader   :mode, :relevance_rank
    attr_accessor :products

    def initialize(mode, relevance) # :nodoc:
      @mode = mode
      @relevance_rank = relevance.to_i
    end

  end

end
  

class Fixnum

  # AWS is often unreliable, so this method provides an easy way of calling a
  # block of code multiple times and ignoring exceptions of the classes named
  # in _exception_list_. _exception_list_ may be a single Exception object or
  # an Array of Exception objects.
  #
  # Any such exceptions raised during the first _n_ - 1 iterations are ignored
  # and a period of _delay_ seconds is inserted before each retry. If the
  # block still yields a listed exception on the _n_th pass, that exception
  # will be raised. The default exception class of +StandardError+ will catch
  # this class and all of its subclasses, which includes all exception classes
  # that Ruby/Amazon defines.
  #
  # For example, the following code makes 3 attempts to retrieve all pages for
  # a given wishlist:
  #
  #  require 'amazon/search'
  #  include Amazon::Search
  #
  #  req = Request.new('D23XFCO2UKJY82')
  #
  #  resp = 3.attempts do |x|
  #    puts "Attempt #{x}..."
  #    req.wishlist_search('RMPWOC6X3DLC', LITE, ALL_PAGES)
  #  end
  #
  #  puts resp.products
  #
  def attempts(exception_list=StandardError, delay=1)
    return if self <= 0

    result = nil

    count = 0
    loop do

      begin
	reason = nil
	result = yield(count += 1)
      rescue *exception_list => reason
	if count < self
	  sleep delay
	  retry
	end
      end

      if reason
	raise reason
      else
	return result
      end

    end
  end
end
