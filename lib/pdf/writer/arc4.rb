#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: arc4.rb,v 1.2 2005/05/16 03:59:21 austin Exp $
#++
require 'digest/md5'

  # ARC4 methods
  # A series of function to implement ARC4 encoding in Ruby
class PDF::Writer::ARC4
    # Initializes the ARC4 encryption with the specified key.
  def initialize(key)
    @key = key
  end

    # Initialize the encryption for processing a particular object.
  def prepare(object)
    hex = ("%06x" % [object.oid]).scan(/../).reverse
    init(Digest::MD5.digest("#{@key}#{hex.pack('H10')}")[0...10])
  end

    # Initialize the ARC4 encryption.
  def init(key)
    @arc4 = ""

      # Setup the control array
    return if key.empty?

    a = []
    (0..255).each { |ii| a[ii] = "%c" % ii }

    k = (key * 256)[0..255].split(//)

    jj = 0
    @arc4.each_with_index do |el, ii|
      jj = ((jj + el.to_i) + k[ii].to_i) % 256
      a[ii], a[jj] = a[jj], a[ii]
    end
    @arc4 = a.join
  end

    # ARC4 encrypt a text string
  def encrypt(text)
    len = text.size
    a = b = 0
    c = @arc4.dup
    out = ""

    text.each_byte do |x|
      a = (a + 1) % 256
      b = (b + c[a].to_i) % 256
      c[a], c[b] = c[b], c[a]
      k = (c[(c[a].to_i + c[b].to_i) % 256]).to_i
      out << ("%c" % (x.to_i ^ k))
    end
    out
  end
end
