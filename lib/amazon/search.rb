# $Id: search.rb,v 1.141 2006/08/08 18:54:03 ianmacd Exp $
#

require 'amazon'
require 'amazon/search/cache'
require 'net/http'
require 'uri'
require 'rexml/document'

module Amazon

  # Load this module with:
  #
  #  require 'amazon/search'
  #
  # This module provides basic Amazon search operations.
  #
  module Search

    # Perform a _HEAVY_ search when you want AWS to return all data that it
    # has on a given search result.
    #
    HEAVY		= true

    # Perform a _LITE_ search when you just want a small subset of the data
    # that AWS has for a given search result. See the AWS documentation for
    # more details.
    #
    LITE		= false
    LIGHT		= false

    # Use the special constant _ALL_PAGES_ when you are performing a search
    # that accepts a page number as a parameter, but you want to retrieve
    # _all_ pages, not just a single page.
    #
    ALL_PAGES		= 0

    # The following constants govern whether all editions of books are
    # returned when performing Request#author_search, Request#keyword_search
    # and Request#power_search.
    #
    ALL_EDITIONS	= true
    SINGLE_EDITION	= false

    # _RATE_LIMIT_REQUESTS_ must be +true+ for compliance with Amazon Web
    # Services regulations, which stipulate no more than one search per
    # second.
    #
    RATE_LIMIT_REQUESTS	= true

    # Maximum number of ASINs that can be handled by a _lite_ search.
    #
    MAX_LITE_ASINS	= 30

    # Maximum number of ASINs that can be handled by a _heavy_ search.
    #
    MAX_HEAVY_ASINS	= 10

    # Maximum number of UPCs that can be handled by a _lite_ search.
    #
    MAX_LITE_UPCS	= 30

    # Maximum number of UPCs that can be handled by a _heavy_ search.
    #
    MAX_HEAVY_UPCS	= 10

    # Maximum number of 301 and 302 HTTP responses to follow, should Amazon
    # later decide to change the location of the service.
    #
    MAX_REDIRECTS = 3

    # :stopdoc:

    # The server to contact for the various Amazon locales.
    #
    LOCALES = { 'ca' => 'xml.amazon.ca',
		'de' => 'xml-eu.amazon.com',
		'fr' => 'xml.amazon.fr',
		'jp' => 'xml.amazon.co.jp',
		'uk' => 'xml-eu.amazon.com',
		'us' => 'xml.amazon.com',
    }

    # The mode to use for each category of product in the various Amazon
    # locales.
    #
    MODES = { 'books'	      => { 'uk' => 'books-uk',
				   'de' => 'books-de',
				   'jp' => 'books-jp',
				   'fr' => 'books-fr',
				   'ca' => 'books-ca'
				 },
	      'music'	      => { 'uk' => 'music',
				   'de' => 'pop-music-de',
				   'jp' => 'music-jp',
				   'fr' => 'music-fr',
				   'ca' => 'music-ca'
				 },
	      'classical'     => { 'uk' => 'classical',
				   'de' => 'classical-de',
				   'jp' => 'classical-jp',
				   'fr' => 'classical-fr',
				   'ca' => 'classical-ca'
				 },
	      'dvd'	      => { 'uk' => 'dvd-uk',
				   'de' => 'dvd-de',
				   'jp' => 'dvd-jp',
				   'fr' => 'dvd-fr',
				   'ca' => 'dvd-ca'
				 },
	      'vhs'	      => { 'uk' => 'vhs-uk',
				   'de' => 'vhs-de',
				   'jp' => 'vhs-jp',
				   'fr' => 'vhs-fr',
				   'ca' => 'vhs-ca'
				 },
	      'video'	      => { 'uk' => 'video',
				   'de' => 'video',
				   'jp' => 'video-jp',
				   'fr' => nil,
				   'ca' => 'video'
				 },
	      'electronics'   => { 'uk' => 'electronics',
				   'de' => 'ce-de',
				   'jp' => 'electronics-jp',
				   'fr' => nil,
				   'ca' => nil
				 },
	      'kitchen'	      => { 'uk' => 'kitchen-uk',
				   'de' => 'kitchen-de',
				   'jp' => nil,
				   'fr' => nil,
				   'ca' => nil
				 },
	      'software'      => { 'uk' => 'software-uk',
				   'de' => 'software-de',
				   'jp' => 'software-jp',
				   'fr' => 'software-fr',
				   'ca' => 'software-ca'
				 },
	      'videogames'    => { 'uk' => 'video-games-uk',
				   'de' => 'video-games-de',
				   'jp' => 'videogames-jp',
				   'fr' => 'video-games-fr',
				   'ca' => 'video-games-ca'
				 },
	      'magazines'     => { 'uk' => nil,
				   'de' => 'magazines-de',
				   'jp' => nil,
				   'fr' => nil,
				   'ca' => nil
				 },
	      'toys'	      => { 'uk' => 'toys-uk',
				   'de' => nil,
				   'jp' => nil,
				   'fr' => nil,
				   'ca' => nil
				 },
	      'photo'	      => { 'uk' => nil,
				   'de' => 'photo-de',
				   'jp' => nil,
				   'fr' => nil,
				   'ca' => nil
				 },
	      'baby'	      => { 'uk' => nil,
				   'de' => nil,
				   'jp' => nil,
				   'fr' => nil,
				   'ca' => nil
				 },
	      'garden'	      => { 'uk' => nil,
				   'de' => 'garden-de',
				   'jp' => nil,
				   'fr' => nil,
				   'ca' => nil
				 },
	      'pc-hardware'   => { 'uk' => nil,
				   'de' => 'pc-de',
				   'jp' => nil,
				   'fr' => nil,
				   'ca' => nil
				 },
	      'tools'	      => { 'uk' => nil,
				   'de' => 'tools-de',
				   'jp' => nil,
				   'fr' => nil,
				   'ca' => nil
				 },
	      'english-books' => { 'uk' => nil,
				   'de' => 'books-de-intl-us',
				   'jp' => 'books-us',
				   'fr' => 'books-fr-intl-us',
				   'ca' => 'books-ca-en'
				 }
	      # ca has the additional category, 'books-ca-fr', for French
	      # language books.
    }

    # The sort types available to each product mode.
    #
    SORT_TYPES = {
       'books'       => %w[+pmrank +salesrank +reviewrank +pricerank
			   +inverse-pricerank +daterank +titlerank
			   -titlerank],

       'software'    => %w[+pmrank +salesrank +titlerank +price -price],

       'garden'      => %w[+psrank +salesrank +titlerank -titlerank
			   +manufactrank -manufactrank +price -price],

       'tools'       => %w[+psrank +salesrank +titlerank -titlerank
			   +manufactrank -manufactrank +price -price],

       'photo'       => %w[+pmrank +salesrank +titlerank -titlerank],

       'pc-hardware' => %w[+psrank +salesrank +titlerank -titlerank],

       'videogames'  => %w[+pmrank +salesrank +titlerank +price -price],

       'music'       => %w[+psrank +salesrank +artistrank +orig-rel-date
			   +titlerank],

       'office'      => %w[+pmrank +salesrank +titlerank -titlerank
			   +price -price +reviewrank],

       'video'       => %w[+psrank +salesrank +titlerank],

       'electronics' => %w[+pmrank +salesrank +titlerank +reviewrank],

       'dvd'	     => %w[+salesrank +titlerank],

       'kitchen'     => %w[+pmrank +salesrank +titlerank -titlerank
			   +manufactrank -manufactrank +price -price],

       'toys'	     => %w[+pmrank +salesrank +pricerank
			   +inverse-pricerank +titlerank]
    }

    # :startdoc:


    # Returns an Array of valid product search modes, such as:
    #
    # *apparel*, *baby*, *books*, *classical*, *dvd*, *electronics*, *garden*,
    # *kitchen*, *magazines*, *music*, <b>pc-hardware</b> *photo*, *software*,
    # *tools*, *toys*, *universal*, *vhs*, *video*, *videogames*,
    # <b>wireless-phones</b>
    #
    def Search.modes
      %w[apparel baby books classical dvd electronics garden kitchen
	 magazines music pc-hardware photo software tools toys universal vhs
	 video videogames wireless-phones]
    end


    # Returns an Array of valid offer types, such as:
    #
    # *All*, *ThirdPartyNew*, *Used*, *Collectible*, *Refurbished*
    #
    def Search.offer_types
      %w[All ThirdPartyNew Used Collectible Refurbished]
    end


    # Returns an Array of valid sort types for _mode_, or +nil+ if _mode_
    # is invalid.
    #
    def Search.sort_types(mode)
      SORT_TYPES.has_key?(mode) ? SORT_TYPES[mode] : nil
    end


    # This is the class around which most others in this library revolve. It
    # contains the most common search methods and exception classes and is the
    # class from which most others in the library inherit.
    #
    class Request
      attr_reader   :token, :id, :config, :locale
      attr_accessor :cache

      AWS_PREFIX = '/onca/xml3' # :nodoc:

      # :stopdoc:
      WEIGHT	 = { HEAVY => 'heavy',
		     LITE  => 'lite'
		   }
      # :startdoc:

      # Exception class for poorly formed config file.
      #
      class ConfigError < StandardError; end

      # Exception class for failed search requests.
      #
      class SearchError < StandardError; end

      # Exception class for bad developer token.
      # 
      class TokenError < StandardError; end

      # Exception class for bad search terms.
      # 
      class TermError < StandardError; end

      # Exception class for bad search modes.
      # 
      class ModeError < StandardError; end

      # Exception class for bad search types.
      #
      class TypeError < StandardError; end

      # Exception class for bad offer types.
      #
      class OfferError < StandardError; end

      # Exception class for bad locales.
      #
      class LocaleError < StandardError; end

      # Exception class for bad sort types.
      #
      class SortError < StandardError; end

      # Exception class for HTTP errors (anything other than <b>200</b>)
      #
      class HTTPError < StandardError; end


      # Use this method to instantiate a basic search request object.
      # _dev_token_ is your AWS developer
      # token[https://associates.amazon.com/exec/panama/associates/join/developer/application.html],
      # _associate_ is your
      # Associates[https://associates.amazon.com/exec/panama/associates/apply/]
      # ID, _locale_ is the search locale in which you wish to work (*us*,
      # *uk*, *de*, *fr*, *ca* or *jp*), _cache_ is whether or not to utilise
      # a response cache, and _user_agent_ is the name of the client you wish
      # to pass when performing calls to AWS. _locale_ and _cache_ can also be
      # set later, if you wish to change the current behaviour.
      #
      # For example:
      #
      #  require 'amazon/search'
      #  include Amazon::Search
      #
      #  r = Request.new('D23XFCO2UKJY82', 'foobar-20', 'us', false)
      #  
      #  # Do a bunch of things in the US locale with the cache off, then:
      #  #
      #  r.locale = 'uk'		      # Switch to the UK locale
      #  r.id = 'foobaruk-21'		      # Use a different Associates ID
      #                                       # in this locale.
      #  r.cache = Cache.new('/tmp/amazon')   # Start using a cache.
      #
      # Note that reassigning the locale will dynamically and transparently
      # set up a new HTTP connection to the correct server for that locale.
      #
      # You may also put one or more of these parameters in a configuration
      # file, which will be read in the order of <tt>/etc/amazonrc</tt> and
      # <tt>~/.amazonrc</tt>. This allows you to have a system configuration
      # file, but still override some of its directives in a per user
      # configuration file.
      #
      # For example:
      # 
      #  dev_token = 'D23XFCO2UKJY82'
      #  associate = 'calibanorg-20'
      #  cache_dir = '/tmp/amazon/cache' 
      #
      # If you do not provide an Associate ID, the one belonging to the author
      # of the Ruby/Amazon library will be used. If _locale_ is not provided,
      # *us* will be used. If _cache_ == +true+, but you do not specify a
      # _cache_dir_ in a configuration file, <b>/tmp/amazon</b> will be used.
      # However, this last convenience applies only when a Request object is
      # instantiated. In other words, if you started off without a cache, but
      # now wish to use one, you will need to directly assign a Cache object,
      # as shown above.
      #
      # If your environment requires the use a HTTP proxy server, you should
      # define this in the environment variable <em>$http_proxy</em>.
      # Ruby/Amazon will detect this and channel all outbound connections via
      # your proxy server.
      #
      def initialize(dev_token=nil, associate=nil, locale=nil, cache=nil,
		     user_agent = USER_AGENT)

	def_locale = locale
	locale = 'us' unless locale
	locale.downcase!

        configs = [ '/etc/amazonrc' ]
	configs << File.expand_path('~/.amazonrc') if ENV.key?('HOME')
	@config = {}

        configs.each do |config|
          if File.exists?(config) && File.readable?(config)
            Amazon::dprintf("Opening %s ...\n", config)

            File.open(config) { |f| lines = f.readlines }.each do |line|
	      line.chomp!

	      # Skip comments and blank lines
	      next if line =~ /^(#|$)/

	      Amazon::dprintf("Read: %s\n", line)

	      # Store these, because we'll probably find a use for these later
	      begin
		match = line.match(/^(\S+)\s*=\s*(['"]?)([^'"]+)(['"]?)/)
		key, begin_quote, val, end_quote = match[1,4]
		raise ConfigError if begin_quote != end_quote
	      rescue NoMethodError, ConfigError
		raise ConfigError, "bad config line: #{line}"
	      end

	      @config[key] = val

	      # Right now, we just evaluate the line, setting the variable if
	      # it does not already exist
	      eval line.sub(/=/, '||=')
	    end
          end
        end

	# take locale from config file if no locale was passed to method
	locale = @config['locale'] if @config.key?('locale') && ! def_locale
	validate_locale(locale)

	if dev_token.nil?
	  raise TokenError, 'dev_token may not be nil'
	end

	@token	    = dev_token
	@id	    = associate || DEFAULT_ID[locale]
	@user_agent = user_agent
	@cache	    = unless cache == false
			Amazon::Search::Cache.new(@config['cache_dir'] ||
						  '/tmp/amazon')
		      else
			nil
		      end
	self.locale = locale
      end


      def locale=(l)
	old_locale = @locale ||= nil
	@locale = validate_locale(l)

	# Use the new locale's default ID if the ID currently in use is the
	# current locale's default ID.
	@id = DEFAULT_ID[@locale] if @id == DEFAULT_ID[old_locale]

	# We must now set up a new HTTP connection to the correct server for
	# this locale, unless the same server is used for both.
	connect(@locale) unless LOCALES[@locale] == LOCALES[old_locale]
      end


      # Verify the validity of a locale string.
      #
      def validate_locale(l)
	raise LocaleError, "invalid locale: #{l}" unless LOCALES.has_key? l
	l
      end
      private :validate_locale


      # Return an HTTP connection for the current locale.
      #
      def connect(locale)
	if ENV.key? 'http_proxy'
	  uri = URI.parse(ENV['http_proxy'])
	  proxy_user = proxy_pass = nil
	  proxy_user, proxy_pass = uri.userinfo.split(/:/) if uri.userinfo
	  @conn = Net::HTTP::Proxy(uri.host, uri.port,
				   proxy_user,
				   proxy_pass).start(LOCALES[locale])
	else
	  @conn = Net::HTTP::start(LOCALES[locale])
	end
      end
      private :connect
 

      # Encode a string, such that it is suitable for HTTP transmission.
      #
      def url_encode(string)
	# shamelessly plagiarised from Wakou Aoyama's cgi.rb
	string.gsub(/([^ a-zA-Z0-9_.-]+)/n) do
          '%' + $1.unpack('H2' * $1.size).join('%').upcase
        end.tr(' ', '+')
      end
      private :url_encode


      # Convert a US mode string into a localised mode string.
      # 
      # English-language books have their own special mode on non-English
      # speaking sites, so we use the pseudo-mode 'english-books' for the US
      #
      def localise_mode(m)

	if @locale == 'us' && m == 'english-books'
	  raise ModeError, "Invalid mode '#{m}' in locale '#{@locale}'"
	end

	return m if @locale == 'us'

	if MODES[m][@locale].nil?
	  raise ModeError, "Invalid mode '#{m}' in locale '#{@locale}'"
	end

	MODES[m][@locale]
      end
      private :localise_mode


      # Deal with a request for offers.
      #
      def get_offer_string(offer=nil)
	unless offer.nil?
	  if @locale == 'de'
	    raise LocaleError, "search type invalid in '#{@locale}' locale"
	  end

	  unless Search.offer_types.include? offer
	    raise OfferError, "'offerings' must be one of %s" %
			      Search.offer_types.join(', ')
	  end

	  @type = WEIGHT[HEAVY]
	  return "&offer=" << offer
	end

	return ""
      end
      private :get_offer_string


      # Deal with a request for a particular sort type.
      #
      def get_sort_string(sort_type, mode)

	unless sort_type.nil?
	  unless Search.sort_types(mode).include? sort_type
	    raise SortError,
	      "invalid sort type '#{sort_type}' for mode #{mode}"
	  end

	  return "&sort=" << url_encode(sort_type)
	end

	return ""
      end
      private :get_sort_string


      # Search for a product by actor and return an Amazon::Search::Response.
      # If a block is given, that Response's @products will be passed to the
      # block.
      #
      # E.g.
      #
      #  resp = req.actor_search('ricky gervais', 'dvd', LITE, 1,
      #				 '+titlerank', 'ThirdPartyNew')
      #
      def actor_search(actor, mode='dvd', weight=HEAVY, page=1,
		       sort_type=nil, offerings=nil, keyword=nil,
		       price=nil, &block)

	url = AWS_PREFIX + "?t=%s&ActorSearch=%s&mode=%s&f=xml" +
	      "&type=%s&dev-t=%s&page=%s"
	url << "&price="    << price   unless price.nil?
	url << get_offer_string(offerings)
 	@type = WEIGHT[weight]
	sort_string = get_sort_string(sort_type, mode)

	actor = url_encode(actor)

	modes = %w[dvd vhs video]
	unless modes.include? mode
	  raise ModeError, "mode must be one of %s" % modes.join(', ')
	end

	mode = localise_mode(mode)
	url = url % [@id, actor, mode, @type, @token, page] << sort_string
	url << "&keywords=" << url_encode(keyword) unless keyword.nil?

	search(url, &block)
      end


      # Search for a product by artist and return an Amazon::Search::Response.
      # If a block is given, that Response's @products will be passed to the
      # block.
      #
      def artist_search(artist, mode='music', weight=HEAVY, page=1,
			sort_type=nil, offerings=nil, keyword=nil,
			price=nil, &block)

	url = AWS_PREFIX + "?t=%s&ArtistSearch=%s&mode=%s&f=xml" +
	      "&type=%s&dev-t=%s&page=%s"
	url << "&price="    << price   unless price.nil?
	url << get_offer_string(offerings)
 	@type = WEIGHT[weight]
	sort_string = get_sort_string(sort_type, mode)

	artist = url_encode(artist)

	modes = %w[music classical]
	unless modes.include? mode
	  raise ModeError, "mode must be one of %s" % modes.join(', ')
	end

	mode = localise_mode(mode)
	url = url % [@id, artist, mode, @type, @token, page] << sort_string
	url << "&keywords=" << url_encode(keyword) unless keyword.nil?

	search(url, &block)
      end


      # Search for a product by ASIN(s) and returns an
      # Amazon::Search::Response. If a block is given, that Response's
      # @products will be passed to the block. The _offer_page_ parameter is
      # ignored unless _offerings_ is not +nil+.
      #
      def asin_search(asin, weight=HEAVY, offer_page=nil, offerings=nil,
		      &block)

	url = AWS_PREFIX + "?t=%s&AsinSearch=%s&f=xml&type=%s&dev-t=%s"
 	@type = WEIGHT[weight]

	unless offerings.nil?
	  url << get_offer_string(offerings)
	  url << "&offerpage=%s" % (offer_page || 1)
	end

	asin.gsub!(/ /, ',') if asin.is_a? String
	asin = asin.join(',') if asin.is_a? Array

	if asin.count(',') >= (weight ? MAX_HEAVY_ASINS : MAX_LITE_ASINS)
	  raise TermError, "too many ASINs"
	end

	search(url % [@id, asin, @type, @token], &block)
      end


      # Search for a book by author and return an Amazon::Search::Response. If
      # a block is given, that Response's @products will be passed to the
      # block.
      #
      def author_search(author, mode='books', weight=HEAVY, page=1,
			sort_type=nil, offerings=nil, keyword=nil,
			price=nil, editions=SINGLE_EDITION, &block)

	url = AWS_PREFIX + "?t=%s&AuthorSearch=%s&mode=%s&f=xml" +
	      "&type=%s&dev-t=%s&page=%s"
	url << "&price="    << price   unless price.nil?
	url << "&variations=yes"       if editions == ALL_EDITIONS
	url << get_offer_string(offerings)
	sort_string = get_sort_string(sort_type, mode)

 	@type = WEIGHT[weight]
	author = url_encode(author)

	raise ModeError, 'mode must be books' unless mode == 'books'

	mode = localise_mode(mode)
	url = url % [@id, author, mode, @type, @token, page] << sort_string

	search(url, &block)
      end


      # Search for a product by director and return an
      # Amazon::Search::Response. If a block is given, that Response's
      # @products will be passed to the block.
      #
      def director_search(director, mode='dvd', weight=HEAVY, page=1,
			  sort_type=nil, offerings=nil, keyword=nil,
			  price=nil, &block)

	url = AWS_PREFIX + "?t=%s&DirectorSearch=%s&mode=%s&f=xml" +
	      "&type=%s&dev-t=%s&page=%s"
	url << "&keywords=" << url_encode(keyword) unless keyword.nil?
	url << "&price="    << price   unless price.nil?
	url << get_offer_string(offerings)
 	@type = WEIGHT[weight]
	sort_string = get_sort_string(sort_type, mode)

	director = url_encode(director)

	modes = %w[dvd vhs video]
	unless modes.include? mode
	  raise ModeError, "mode must be one of %s" % modes.join(', ')
	end

	mode = localise_mode(mode)
	url = url % [@id, director, mode, @type, @token, page] << sort_string
	url << "&keywords=" << url_encode(keyword) unless keyword.nil?

	search(url, &block)
      end


      # Search for a product by keyword(s) and return an
      # Amazon::Search::Response. If a block is given, that Response's
      # @products will be passed to the block.
      #
      def keyword_search(keyword, mode='books', weight=HEAVY, page=1,
			 sort_type=nil, offerings=nil, price=nil,
			 editions=SINGLE_EDITION, &block)

	url = AWS_PREFIX + "?t=%s&KeywordSearch=%s&mode=%s&f=xml" +
	      "&type=%s&dev-t=%s&page=%s"
	url << "&price=" << price unless price.nil?
	url << "&variations=yes"  if	 editions == ALL_EDITIONS
	url << get_offer_string(offerings)
 	@type = WEIGHT[weight]
	sort_string = get_sort_string(sort_type, mode)

	keyword = url_encode(keyword)

	unless Search.modes.include? mode
	  raise ModeError, "mode must be one of %s" % Search.modes.join(', ')
	end

	mode = localise_mode(mode)
	url = url % [@id, keyword, mode, @type, @token, page] << sort_string

	search(url, &block)
      end


      # Return an Amazon::Search::Response of the products on a Listmania list.
      # If a block is given, that Response's @products will be passed to the
      # block.
      #
      def listmania_search(list_id, weight=HEAVY, &block)

	url = AWS_PREFIX + "?t=%s&ListManiaSearch=%s&f=xml&type=%s&dev-t=%s"
 	@type = WEIGHT[weight]

	unless list_id.length.between?(12, 13)
	  raise TermError, "list ID length must be 12 or 13 characters"
	end

	search(url % [@id, list_id, @type, @token], &block)
      end


      # Search for a product by manufacturer and return an
      # Amazon::Search::Response. If a block is given, that Response's
      # @products will be passed to the block.
      #
      def manufacturer_search(director, mode='electronics', weight=HEAVY,
			      page=1, sort_type=nil, offerings=nil,
			      keyword=nil, price=nil, &block)

	url = AWS_PREFIX + "?t=%s&ManufacturerSearch=%s&mode=%s" +
	      "&f=xml&type=%s&dev-t=%s&page=%s"
	url << "&price="    << price   unless price.nil?
	url << get_offer_string(offerings)
 	@type = WEIGHT[weight]
	sort_string = get_sort_string(sort_type, mode)

	director = url_encode(director)

	modes = %w[electronics kitchen videogames software
		   photo pc-hardware]
	unless modes.include? mode
	  raise ModeError, "mode must be one of %s" % modes.join(', ')
	end

	mode = localise_mode(mode)
	url = url % [@id, director, mode, @type, @token, page] << sort_string
	url << "&keywords=" << url_encode(keyword) unless keyword.nil?

	search(url, &block)
      end



      # Search for a product by browse node. The default of '1000' is for
      # best-selling books. Returns an Amazon::Search::Response. If a block is
      # given, that Response's @products will be passed to the block.
      #
      def node_search(browse_node='1000', mode='books', weight=HEAVY, page=1,
		      sort_type=nil, offerings=nil, keyword=nil, price=nil,
		      &block)

	url = AWS_PREFIX + "?t=%s&BrowseNodeSearch=%s&mode=%s&f=xml" +
	      "&type=%s&dev-t=%s&page=%s"
	url << "&price="    << price   unless price.nil?
	url << get_offer_string(offerings)
 	@type = WEIGHT[weight]
	sort_string = get_sort_string(sort_type, mode)

	if browse_node.is_a? Array
	  raise TypeError, "string or integer required"
	elsif browse_node =~ / /
	  raise TermError, "single item expected"
	end

	unless Search.modes.include? mode
	  raise ModeError, "mode must be one of %s" % Search.modes.join(', ')
	end

	mode = localise_mode(mode)
	url =
	  url % [@id, browse_node, mode, @type, @token, page] << sort_string
	url << "&keywords=" << url_encode(keyword) unless keyword.nil?

	search(url, &block)
      end


      # Search for a book, using a power search, and return an
      # Amazon::Search::Response. If a block is given, that Response's
      # @products will be passed to the block.
      #
      def power_search(query, mode='books', weight=HEAVY, page=1,
		       sort_type=nil, offerings=nil, editions=SINGLE_EDITION,
		       &block)

	url = AWS_PREFIX + "?t=%s&PowerSearch=%s&mode=%s&f=xml" +
	      "&type=%s&dev-t=%s&page=%s"
	url << "&variations=yes" if editions == ALL_EDITIONS
	url << get_offer_string(offerings)
	sort_string = get_sort_string(sort_type, mode)

 	@type = WEIGHT[weight]
	query = url_encode(query)

	raise ModeError, 'mode must be books' unless mode == 'books'

	mode = localise_mode(mode)
	url = url % [@id, query, mode, @type, @token, page] << sort_string

	search(url, &block)
      end


      # Search for a product's similar products and return an
      # Amazon::Search::Response. If a block is given, that Response's
      # @products will be passed to the block.
      #
      def similarity_search(asin, weight=HEAVY, page=1, &block)

	url = AWS_PREFIX + "?t=%s&SimilaritySearch=%s&f=xml" +
	      "&type=%s&dev-t=%s&page=%s"
 	@type = WEIGHT[weight]

	asin.gsub!(/ /, ',') if asin.is_a? String
	asin = asin.join(',') if asin.is_a? Array

	if asin.count(',') >= 5
	  raise TermError, "too many ASINs (max. 5 for this search)"
	end

	search(url % [@id, asin, @type, @token, page], &block)
      end


      # Perform a text stream search and return an Amazon::Search::Response.
      # If a block is given, that Response's @products will be passed to the
      # block.
      #
      def text_stream_search(text_stream, mode='books', weight=HEAVY,
			     sort_type=nil, page=1, &block)

        # this search type not available for international sites
        unless @locale == 'us'
	  raise LocaleError, "search type invalid in '#{@locale}' locale"
        end

        url = AWS_PREFIX + "?t=%s&TextStreamSearch=%s&mode=%s&f=xml" +
	      "&type=%s&dev-t=%s&page=%s"
	@type = WEIGHT[weight]
	sort_string = get_sort_string(sort_type, mode)

	modes = %w[electronics books videogames apparel toys photo
		   music dvd wireless-phones]
	unless modes.include? mode
	  raise ModeError, "mode must be one of %s" % modes.join(', ')
	end

	# strip a few useless words from the text stream
	%w[and or not the a an but to for of on at].each do |particle|
	  text_stream.gsub!(/\b#{particle}\b/, '')
	end

	text_stream = url_encode(text_stream)
	url =
	  url % [@id, text_stream, mode, @type, @token, page] << sort_string

	search(url, &block)
      end


      # Search for a product by UPC code(s) and return an
      # Amazon::Search::Response. If a block is given, that Response's
      # @products will be passed to the block.
      #
      def upc_search(upc, mode='music', weight=HEAVY, &block)

	unless @locale == 'us'
	  raise LocaleError, "search type invalid in '#{@locale}' locale"
	end

	url = AWS_PREFIX + "?t=%s&UpcSearch=%s&mode=%s&f=xml&type=%s&dev-t=%s"
 	@type = WEIGHT[weight]

	upc.gsub!(/ /, ',') if upc.is_a? String
	upc = upc.join(',') if upc.is_a? Array

	if upc.count(',') >= (weight ? MAX_HEAVY_UPCS : MAX_LITE_UPCS)
	  raise TermError, "too many UPCs"
	end

	modes = %w[music classical software dvd vhs video
		   electronics pc-hardware photo]
	unless modes.include? mode
	  raise ModeError, "mode must be one of %s" % modes.join(', ')
	end

	mode = localise_mode(mode)
	search(url % [@id, upc, mode, @type, @token], &block)
      end


      # Return an Amazon::Search::Response of the products on a wishlist.
      # If a block is given, that Response's @products will be passed to the
      # block.
      #
      def wishlist_search(list_id, weight=HEAVY, page=1, &block)

	url = AWS_PREFIX + "?t=%s&WishlistSearch=%s&f=xml" +
	      "&type=%s&dev-t=%s&page=%s"
 	@type = WEIGHT[weight]

	unless list_id.length.between?(12, 13)
	  raise TermError, "list ID length must be 12 or 13 characters"
	end

	search(url % [@id, list_id, @type, @token, page], &block)
      end


      # Handle non-existent and unimplemented search types.
      #
      def method_missing(*params)
	raise TypeError,
	      "non-existent/unimplemented search type: #{params[0].id2name}"
      end
      private :method_missing


      # Get page, but throw exception if there's an HTTP error
      #
      def get_page(url)	  # :nodoc:

	# check for cached page and return that if it's there
	if @cache && @cache.cached?(url)
	  body = @cache.get_cached(url)
	  return body if body
	end

	Amazon::dprintf("Fetching http://%s%s ...\n", @conn.address, url)
	response = @conn.get(url, { 'user-agent', @user_agent })

	redirects = 0
	while response.key?('location')
	  if (redirects += 1) > MAX_REDIRECTS
	    raise HTTPError, "More than #{MAX_REDIRECTS} redirections"
	  end

	  old_url = url
	  url = URI.parse(response['location'])
	  url.scheme = old_url.scheme unless url.scheme
	  url.host = old_url.host unless url.host
	  Amazon::dprintf("Following HTTP %s to %s ...\n", response.code, url)
	  response = Net::HTTP::start(url.host).
		       get(url.path,{ 'user-agent', @user_agent })
	end

	if response.code != '200'
	  raise HTTPError, "HTTP response code #{response.code}"
	end

	# cache the page if we're using a cache and it's not the result of
	# a shopping cart transaction
	if @cache && ! is_a?(Amazon::ShoppingCart)
	  @cache.cache(url, response.body)
	end

	response.body
      end


      # Perform the actual search.
      #
      def search(url, &block) # :nodoc:
	url << "&locale=" << @locale

	# determine whether we need to retrieve all pages
	all_pages = url.sub!(/page=#{ALL_PAGES}/, 'page=1')

	# get the page
	body = get_page(url)

	body = case self
	       when Amazon::Search::Exchange::Marketplace::Request
		 Exchange::Marketplace::Response.new(body)

	       when Amazon::Search::Exchange::ThirdParty::Request
		 Exchange::ThirdParty::Response.new(body)

	       when Amazon::Search::Exchange::Request
		 Exchange::Response.new(body)

	       when Amazon::Search::Blended::Request
		 Blended::Response.new(body)

	       when Amazon::Search::Seller::Request
		 Seller::Response.new(body)

	       when Amazon::ShoppingCart
		 Amazon::ShoppingCart::Response.new(body)

	       else   # must be Amazon::Search::Request
		 Response.new(body)
	       end

	if caller[0] =~ /`wishlist_search'$/
	  body.products = body.products.reverse
	end

	if all_pages
	  responses = [body]
	  threads = []

	  begin
	    total_pages = body.products.total_pages
	  rescue
	    raise SearchError, 'failed to determine total number of pages'
	  end

	  # Get second and subsequent pages in parallel
	  2.upto(total_pages) do |page_nr|

	    # be nice to Amazon
	    sleep 1 if RATE_LIMIT_REQUESTS &&
		      ! ENV.key?('AMAZON_NO_RATE_LIMIT')

	    threads << Thread.new(url) do |paged_url|

	      req = Request.new(@token, @id, @locale, @cache, @user_agent)

	      # increment page number
	      paged_url.sub!(/page=\d+/) { |s| "page=#{page_nr}" }

	      # go on and get next body, appending to our list
	      response = Response.new(req.get_page(paged_url))
	      responses << response
	    end
	  end
	  threads.each { |t| t.join }

	  if responses.size != body.products.total_pages
	    raise SearchError, "Failed to get all pages"
	  end

	  # Define a singleton method for this Array, so that we can retrieve
	  # all products of each Response in a single method call. I.e.
	  # there's no need to do something like this:
	  #
	  # responses.each { |r| r.products.each { |p| puts p } }
	  #
	  # Instead, we can do this:
	  #
	  # responses.products.each { |p| puts p }
	  #
	  def responses.products
	    products = []
	    each { |page| products << page.products }
	    products.flatten!
	  end

	  # return an Array of Responses, sorted on page number
	  responses.sort! { |a,b| a.args['page'].to_i <=> b.args['page'].to_i }

	  responses.products.each(&block) if block_given?
	  responses

	else
	  # return a single Response
	  body.products.each(&block) if block_given?
	  body
	end
      end
      private :search

    end


    class Response < String

      attr_reader :stream	      # :nodoc:
      attr_reader :args

      attr_accessor :products

      def initialize(stream)
	@args = {}
	@error = nil
	@stream = nil

	if stream.is_a? File
	  # we were passed an open file handle -- slurp it as a string
	  @stream = stream
	  super stream.readlines(nil)[0]
	  @stream.close
	elsif stream.is_a? REXML::Element
	  @stream = stream
	else  # String
	  super stream
	end

	parse

      end


      # Parse the request/response arguments.
      #
      def get_args(node, detail_node=node)  # :nodoc:
        node.elements.each('Request/Args/Arg') do |arg|
          key = arg.attributes['name']
          val = arg.attributes['value']
          @args[key] = val
        end

	Amazon::dprintf("Response args = %s\n", @args.inspect)

	# Check for the presence of actual results.
	#
	unless detail_node.has_elements?
	  @error = "empty result set"
	  raise Amazon::Search::Request::SearchError, @error
	end

	begin
	  if node.elements['ErrorMsg'].nil?
	    @error = detail_node.elements['ErrorMessage'].text
	  else
	    @error = detail_node.elements['ErrorMsg'].text
	  end

	  raise Amazon::Search::Request::SearchError, @error

	rescue NoMethodError
	  # AWS has not reported an error on their side.
	end

	if @args.empty? && ! @stream.is_a?(File)
	  raise Amazon::Search::Request::SearchError,
	        "response contained no arguments"
	end

      end


      # Convert a string from CamelCase to ruby_case
      #
      def uncamelise(str)
	str.gsub(/(.[a-z])(?=[A-Z])/, "\\1_\\2").downcase 
      end
      private :uncamelise


      # Parse an XML Amazon::Search::Request and return an
      # Amazon::Search::Response.
      #
      def parse
	@products = []

	# create a singleton #inspect for looking at this Array, including
	# its instance variables for TotalResults and TotalPages.
	#
	class << @products  # :nodoc:
	  attr_accessor :total_results, :total_pages
	  alias_method	:old_inspect, :inspect

	  def inspect

	    str = ""

	    unless @total_pages.nil?
	      str << "@total_pages=#{@total_pages}, " +
	      str << "@total_results=#{@total_results},\n"
	    end
	    str << old_inspect
	  end
	end

	if @stream.nil? || @stream.is_a?(File)
	  doc = REXML::Document.new(self).elements['ProductInfo']

	  # populate @args with header data
	  get_args(doc) if @args.empty?
	else
	  doc = @stream
	end

	begin
	  @products.total_results = doc.elements['TotalResults'].text.to_i
	  @products.total_results.freeze
	  @products.total_pages = doc.elements['TotalPages'].text.to_i
	  @products.total_pages.freeze
	rescue
	  @products.total_results = nil
	  @products.total_pages = nil
	end

	doc.elements.each('Details') do |detail|
	  product = Product.new(detail.attributes['url'])

	  detail.elements.each do |property|

	    if property.has_elements?

	      case property.name
	      # deal with elements that have more than one sub-level

	      when 'BrowseList'
		browsenames = property.elements.map do |e|
				e.elements.map { |e| e.text }
			      end.flatten
		product.instance_variable_set(:@browse_list, browsenames)

	      when 'Reviews'
		# can be either AverageCustomerRating or AverageRating
		avg = property.elements[1].text.to_f
		tcr = property.elements[2].text.to_i

		list =
		  property.elements.map { |e| e.elements.map { |e| e.text } }
		reviews = []
		list.each do |r|
		  reviews << Product::Review.new(*r) unless r.empty?
		end

		product.instance_variable_set(:@average_customer_rating, avg)
		product.instance_variable_set(:@total_customer_reviews, tcr)
		product.instance_variable_set(:@reviews, reviews)

	      when 'ThirdPartyProductInfo'  # Offerings returns these

		info = []
		property.elements.map do |e|
		  tpi = Product::ThirdPartyInfo.new
		  e.elements.map do |e|
		    iv, value = e.name, e.text
		    value = value.to_i if value.to_i > 0

		    unless value.nil?
		      # normalise instance variable's name
		      iv = uncamelise(iv)
		      tpi.instance_variable_set("@#{iv}".to_sym, value)
		    end

		  end

		  info << tpi
		end

		product.instance_variable_set(:@third_party_product_info, info)

	      else  # deal with the rest
		members = property.elements.map { |e| e.text }

		iv = uncamelise(property.name)
		product.instance_variable_set("@#{iv}".to_sym, members)
	      end

	    else	# these elements have no children

	      value = property.text
	      value = value.gsub(/,/, '').to_i if property.name =~ /Num|Rank/

	      iv = uncamelise(property.name)
	      product.instance_variable_set("@#{iv}".to_sym, value)
	    end

	  end

	  @products << product

	end

	self

      end
      private :parse

    end

  end
end

require 'amazon/search/blended'
require 'amazon/search/exchange'
require 'amazon/search/exchange/marketplace'
require 'amazon/search/exchange/thirdparty'
require 'amazon/search/seller'
require 'amazon/shoppingcart'
