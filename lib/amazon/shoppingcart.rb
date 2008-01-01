# $Id: shoppingcart.rb,v 1.31 2006/08/05 19:39:49 ianmacd Exp $

require 'amazon/search'

module Amazon

  # Load this library with:
  #
  #  require 'amazon/shoppingcart'
  #
  # This class provides access to Amazon's Remote Shopping Cart
  # functionality.
  #
  class ShoppingCart < Search::Request

    attr_reader :purchase_url, :items, :similarities


    # Exception class for shopping cart errors.
    #
    class CartError < SearchError; end


    # Exception class for shopping cart quantity errors.
    #
    class QuantityError < SearchError; end


    # Shopping cart transactions return an Amazon::ShoppingCart object that
    # contains, amongst other things, an Array of Amazon::ShoppingCart::Item
    # objects.
    #
    class Item < Amazon::Product

      attr_reader :item_id, :product_name, :merchant_sku, :asin,
		  :quantity, :list_price, :our_price

      def initialize(item_id, product_name, merchant_sku, asin, quantity,
		     list_price, our_price)   # :nodoc:

	@item_id = item_id
	@product_name = product_name
	@merchant_sku = merchant_sku
	@asin = asin
	@quantity = quantity
	@list_price = list_price
	@our_price = our_price
      end
    end

    
    # Returns an HTML form to add an item to the shopping cart.
    #
    def ShoppingCart.add_items_form(associate, dev_id, asin_list, locale='us')

      associate ||= DEFAULT_ID[locale]
      locale.downcase!
      site = SITE[locale]
      asin_list = [asin_list] if asin_list.is_a? String

      html = <<"EOF"
<form method="POST" action="http://#{site}/exec/obidos/dt/assoc/handle-buy-box=#{asin_list[0]}">
EOF

      asin_list.each do |asin|
	html << %Q[<input type="hidden" name="asin.#{asin}" value="1">]
      end

      html = <<"EOF"
<input type="hidden" name="tag-value" value="#{associate}">
<input type="hidden" name="tag_value" value="#{associate}">
<input type="hidden" name="dev-tag-value" value="#{dev_id}">
<input type="submit" name="submit.add-to-cart" value="Buy From Amazon #{locale}">
</form>
EOF
    end


    # Returns an HTML form to add a Marketplace item to the shopping cart.
    #
    def ShoppingCart.add_marketplace_item_form(associate, dev_id, asin,
					       exchange_id, seller_id,
					       locale='us')
      locale.downcase!
      site = SITE[locale]

      <<"EOF"
<form method="POST" action="http://#{site}/exec/obidos/dt/assoc/handle-buy-box=#{asin}">
<input type=hidden name="exchange.#{exchange_id}.#{asin}.#{seller_id}" value="1">
<input type="hidden" name="tag-value" value="#{associate}">
<input type="hidden" name="tag_value" value="#{associate}">
<input type="hidden" name="dev-tag-value" value="#{dev_id}">
<input type="submit" name="submit.add-to-cart" value="Buy From Amazon #{locale}">
</form>
EOF
    end


    # Returns an HTML form to allow the user to purchase an item through
    # Amazon's 1-Click® technology.
    # 
    def ShoppingCart.one_click_form(associate, dev_id, asin, locale='us')

      locale.downcase!

      unless locale == 'us'
	raise LocaleError, "form type invalid in '#{locale}' locale"
      end

      # Why is no developer token used in the form below? It *is* used by
      # all other HTML forms.
      #
      <<"EOF"
<script language="JavaScript">
function popUp(URL,NAME) {
amznwin=window.open(URL,NAME,'location=yes,scrollbars=yes,status=yes,toolbar=yes,resizable=yes,width=380,height=450,screenX=10,screenY=10,top=10,left=10');
amznwin.focus();}
document.open();
document.write("<a href=javascript:popUp('http://buybox.amazon.com/exec/obidos/redirect?tag=#{associate}&link_code=qcb&creative=23424&camp=2025&path=/dt/assoc/tg/aa/xml/assoc/-/#{asin}/#{associate}/ref=ac_bb1_,_amazon')><img src=http://rcm-images.amazon.com/images/G/01/associates/remote-buy-box/buy1.gif border=0 alt='Buy from Amazon.com' ></a>");
document.close();
</script>
<noscript>
<form method="POST" action="http://buybox.amazon.com/o/dt/assoc/handle-buy-box=#{asin}">
<input type="hidden" name="asin.#{asin}" value="1">
<input type="hidden" name="tag-value" value="#{associate}">
<input type="hidden" name="tag_value" value="#{associate}">
<input type="image" name="submit.add-to-cart" value="Buy from Amazon.com" border="0" alt="Buy from Amazon.com" src="http://rcm-images.amazon.com/images/G/01/associates/add-to-cart.gif">
</form>
</noscript>
EOF
    end


    def initialize(dev_token=nil, associate=nil, locale='us',
		   user_agent = USER_AGENT)

      @cart_id = @hmac = @data = nil
      @args = {}
      super
    end


    # Parse the response from the shopping cart transaction.
    #
    def get_args(node)
      return if node.nil?

      node.elements.each('Request/Args/Arg') do |arg|
        key = arg.attributes['name']
        val = arg.attributes['value']
        @args[key] = val
      end

      Amazon::dprintf("Response args = %s\n", @args.inspect)

      begin
        @error = node.elements['ErrorMsg'].text
        raise CartError, @error
      rescue NoMethodError
        # we found no error text, so there was no error
      end

      if @args.empty? && ! @stream.is_a?(File)
        raise CartError, "response contained no arguments"
      end

    end
    private :get_args

    
    # Check for good cart ID and hashed message authentication code (HMAC).
    #
    def check_cart(url)

      if (@cart_id && ! @hmac) || (@hmac && ! @cart_id)
	faulty = @cart_id ? "@hmac" : "@cart_id"
	raise CartError, "#{faulty} is not set"
      end
      
      url << "&CartId=" << @cart_id	     unless @cart_id.nil?
      url << "&Hmac="	<< url_encode(@hmac) unless @hmac.nil?

      url
    end
    private :check_cart


    # Check the quantity passed to a transaction method.
    #
    def check_minimum_quantity(quantity, minimum)
      if quantity < minimum
	raise QuantityError, "must be at least #{minimum} items"
      end
    end
    private :check_minimum_quantity


    # Add an item or items to a shopping cart. _asin_list_ may be a String
    # containing a single ASIN or an Array containing multiples. _quantity_
    # should be greater than zero.
    #
    def add_items(asin_list, quantity)

      check_minimum_quantity(quantity, 1)

      url = AWS_PREFIX + "?ShoppingCart=add&f=xml&dev-t=%s&t=%s&sims=true"
      url = url % [@token, @id]

      asin_list = [asin_list] if asin_list.is_a? String

      asin_list.each { |asin| url << "&Asin.%s=%s" % [asin, quantity] }

      url = check_cart(url)

      @page = search(url)
      parse
    end


    # Modify an item or items in a shopping cart. _item_list_ may be a String
    # containing a single item ID (not ASIN) or an Array containing multiples.
    # _quantity_ should be zero or greater. Specifying zero has the effect of
    # removing the item from the cart and is an alternative to directly
    # calling remove_items in your code.
    #
    def modify_items(item_list, quantity)

      check_minimum_quantity(quantity, 0)

      # If quantity is zero, use remove_items instead, as Amazon's 'modify'
      # operation can't handle removal.
      return remove_items(item_list) if quantity == 0

      url = AWS_PREFIX + "?ShoppingCart=modify&f=xml&dev-t=%s&t=%s&sims=true"
      url = url % [@token, @id]

      item_list = [item_list] if item_list.is_a? String

      item_list.each { |item| url << "&Item.%s=%s" % [item, quantity] }

      url = check_cart(url)

      @page = search(url)
      parse
    end

 
    # Remove an item or items from a shopping cart. _item_list_ may be a
    # String containing a single item ID (not ASIN) or an Array containing
    # multiples. An alternative to using this method is to call modify_items
    # with a quantity of zero.
    #
    def remove_items(item_list)

      url = AWS_PREFIX + "?ShoppingCart=remove&f=xml&dev-t=%s&t=%s&sims=true"
      url = url % [@token, @id]

      item_list = [item_list] if item_list.is_a? String

      item_list.each { |item| url << "&Item." << item }

      url = check_cart(url)
      @page = search(url)

      parse
    end


    # Retrieve the items in a shopping cart.
    #
    def retrieve_items

      # We should theoretically be able to just 'return self' here, but
      # let's actually query Amazon and get the contents of the cart, just
      # in case some unknown factor has caused it to diverge from what we
      # think the state is.

      url = AWS_PREFIX + "?ShoppingCart=get&f=xml&dev-t=%s&t=%s&sims=true"
      url = url % [@token, @id]
      url = check_cart(url)

      @page = search(url)
      parse
    end


    # Empty a shopping cart. This method has an alias, #empty. Note that the
    # cart, itself, is not destroyed. You may continue to add items to it.
    #
    def clear

      url = AWS_PREFIX + "?ShoppingCart=clear&f=xml&dev-t=%s&t=%s&sims=true"
      url = url % [@token, @id]
      url = check_cart(url)

      @page = search(url)
      parse
    end
    alias_method :empty, :clear


    # This method presents the illusion of the shopping cart being a Hash,
    # indexed on ASIN. Unfortunately, if the same ASIN is added to the cart
    # more than once, it will appear multiple times. In other words, if you
    # add 3 copies of a book to the cart and then later add another 4, there
    # will be two entries in the cart, not one with 7 copies.
    #
    # For this reason, this method returns an Array of
    # Amazon::ShoppingCart::Item objects, one for each line item of the
    # shopping cart that matched _asin_.
    #
    def [](asin)
      @items.find_all { |item| item.asin == asin }
    end


    def parse

      # check for error
      get_args(REXML::Document.new(@page).elements['ProductInfo'])

      doc = REXML::Document.new(@page).elements['ShoppingCartResponse']
      
      doc = doc.elements['ShoppingCart']

      @cart_id = doc.elements['CartId'].text
      @hmac = doc.elements['HMAC'].text

      # Purchase URL is known to work for Amazon US and UK now. Perhaps it
      # works for all locales, so we no longer check for the locale.
      @purchase_url = doc.elements['PurchaseUrl'].text

      items = []

      doc.elements.each('Items/Item') do |item|
	item_id = item.elements['ItemId'].text
	product_name = item.elements['ProductName'].text
	asin = item.elements['Asin'].text
	quantity = item.elements['Quantity'].text.to_i
	list_price = item.elements['ListPrice'].text
	our_price = item.elements['OurPrice'].text

	# AWS seems to have stopped returning MerchantSku, so make it
	# optional
	if item.elements['MerchantSku']
	  merchant_sku = item.elements['MerchantSku'].text
	else
	  merchant_sku = nil
	end

	items << Item.new(item_id, product_name, merchant_sku, asin,
			  quantity, list_price, our_price)
      end

      similarities = []

      doc.elements.each('SimilarProducts/Product') do |asin|
	similarities << asin.text
      end

      @items = items
      @similarities = similarities

      @page

    end
    private :parse


    class Response < String
      def initialize(page)
	super page
      end
    end

  end
 
end
