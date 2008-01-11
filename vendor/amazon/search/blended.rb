# $Id: blended.rb,v 1.18 2004/03/10 09:48:39 ianmacd Exp $

module Amazon
  module Search

    # This module provides functionality related to blended searches, which
    # are search operations that span multiple product categories.
    #
    module Blended

      class Request < Amazon::Search::Request

	# A blended search returns results across up to 15 of Amazon's
	# product categories in an Amazon::Search::Blended::Response. If a
	# block is given, that Response's @product_lines, which is an Array of
	# Amazon::ProductLine objects, will be passed to the block.
	# 
	def search(keyword, weight=HEAVY, &block)
	  url = AWS_PREFIX + "?t=%s&BlendedSearch=%s&f=xml&type=%s&dev-t=%s"

	  type = WEIGHT[weight]
	  keyword = url_encode(keyword)

	  super(url % [@id, keyword, type, @token], &block)
	end
 
      end


      class Response < Amazon::Search::Response

	attr_reader :product_lines

	# Parse the XML response from a Blended::Request and populate
	# @product_lines with an Array of Amazon::ProductLine objects.
	#
	def parse

	  # @products needs to refer to same data structure as @product_lines
	  # for block call in #parse method of super-class.
	  #
	  @products = @product_lines = []

	  doc = REXML::Document.new(self).elements['BlendedSearch']

	  # populate args from top of doc
	  get_args(doc)

	  doc.elements.each('ProductLine') do |line|

	    mode = line.elements['Mode'].text
	    relevance = line.elements['RelevanceRank'].text.to_i
	    product_line = Amazon::ProductLine.new(mode, relevance)

	    product_line.products = Amazon::Search::Response.new(
				      line.elements['ProductInfo']).products

	    @product_lines << product_line

	  end

	  self

	end
	private :parse

      end

    end
  end
end
