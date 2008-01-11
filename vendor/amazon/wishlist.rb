# $Id: wishlist.rb,v 1.12 2004/03/10 09:48:39 ianmacd Exp $

require 'amazon'

module Amazon

  # Load this module with:
  #
  #  require 'amazon/wishlist'
  #
  # This module provides access to Amazon Wishlist functionality.
  #
  module Wishlist

    # Returns an HTML form to add an item to a wishlist.
    #
    def add_item_form(associate, dev_id, asin, locale='us')

      associate ||= DEFAULT_ID[locale]
      locale.downcase!
      site = SITE[locale]

      <<"EOF"
<form method="POST" action="http://#{site}/exec/obidos/dt/assoc/handle-buy-box=#{asin}">
<input type="hidden" name="asin.#{asin}" value="1">
<input type="hidden" name="tag-value" value="#{associate}">
<input type="hidden" name="tag_value" value="#{associate}">
<input type="hidden" name="dev-tag-value" value="#{dev_id}">
<input type="submit" name="submit.add-to-registry.wishlist" value="Add to Amazon #{locale} Wish List">
</form>
EOF
    end
    module_function :add_item_form

  end
end
