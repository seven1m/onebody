# $Id: seller.rb,v 1.23 2004/03/21 02:49:31 ianmacd Exp $

module Amazon
  module Search

    # This module provides search functionality related to Amazon sellers.
    #
    module Seller

      class Request < Amazon::Search::Request

	# Seller profile search. This returns an
	# Amazon::Search::Seller::Response. If a block is given, that
	# Response's @seller, which is an Amazon::Seller object, will be
	# passed to the block.
	#
	def search(seller_id, weight=HEAVY, page=1, &block)

	  # this search type not available for international sites
	  unless @locale == 'us'
	    raise LocaleError, "search type invalid in '#{@locale}' locale"
	  end

	  url = AWS_PREFIX + "?t=%s&SellerProfile=%s&f=xml" +
		"&type=%s&dev-t=%s&page=%s"

	  type = WEIGHT[weight]

	  super(url % [@id, seller_id, type, @token, page], &block)
	end

      end


      class Response < Amazon::Search::Response

	attr_reader :seller

	# Parse the XML response from an Amazon::Search::Seller::Request and
	# populate @seller with an Amazon::Seller object.
	#
	def parse

	  begin
	    doc = REXML::Document.new(self).elements['SellerProfile']
	    detail_node = doc.elements['SellerProfileDetails'] || doc
	  rescue NoMethodError
	    doc = REXML::Document.new(self).elements['ProductInfo']
	    detail_node = doc
	  end

	  # populate args from top of doc
	  get_args(doc, detail_node)

	  doc = detail_node

	  begin
	    seller_nickname = doc.elements['SellerNickname'].text
	    overall_feedback_rating =
	      doc.elements['OverallFeedbackRating'].text
	    nr_feedback = doc.elements['NumberOfFeedback'].text
	    store_id = doc.elements['StoreId'].text
	    store_name = doc.elements['StoreName'].text
	  rescue
	    # these searches often fail for no apparent reason
	    raise SearchError, self
	  end

	  all_feedback = []

	  doc.elements.each('SellerFeedback/Feedback') do |feedback|
	    feedback_rating = feedback.elements['FeedbackRating'].text
	    feedback_comments = feedback.elements['FeedbackComments'].text
	    feedback_date = feedback.elements['FeedbackDate'].text
	    feedback_rater = feedback.elements['FeedbackRater'].text

	    all_feedback << Amazon::Feedback.new(feedback_rating,
						 feedback_comments,
						 feedback_date,
						 feedback_rater)
	  end

	  # @products needs to refer to same data structure as @seller
	  # for block call in #parse method of super-class.
	  #
	  @seller = @products = Amazon::Seller.new(seller_nickname,
						   overall_feedback_rating,
						   nr_feedback,
						   store_id,
						   store_name,
						   all_feedback)

	  self

	end
	private :parse

      end

    end
  end
end
