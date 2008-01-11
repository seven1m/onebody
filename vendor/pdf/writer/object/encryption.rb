#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   Licensed under a MIT-style licence. See LICENCE in the main distribution
#   for full licensing information.
#
# $Id: encryption.rb,v 1.2 2005/05/16 03:59:21 austin Exp $
#++
  # Encryption object
class PDF::Writer::Object::Encryption < PDF::Writer::Object
  PAD = [ 0x28, 0xBF, 0x4E, 0x5E, 0x4E, 0x75, 0x8A, 0x41,
          0x64, 0x00, 0x4E, 0x56, 0xFF, 0xFA, 0x01, 0x08,
          0x2E, 0x2E, 0x00, 0xB6, 0xD0, 0x68, 0x3E, 0x80,
          0x2F, 0x0C, 0xA9, 0xFE, 0x64, 0x53, 0x69, 0x7A ].pack("C*")

  def initialize(parent, options)
    super(parent)

    @parent.encrypt_obj = self

      # Figure out the additional parameters required.
    @owner  = "#{options[:owner_pass]}#{PAD}"[0...32]
    @user   = "#{options[:user_pass]}#{PAD}"[0...32]
    @perms  = options[:permissions]

    @parent.arc4.prepare(Digest::MD5.hexdigest(@owner)[0...5])

      # Get the 'O' value.
    @owner_info = ARC4.encrypt(@user)
      # Get the 'U' value.
    ukey = @user.dup
    ukey << @owner_info
    ukey << [ @perms, 0xFF, 0xFF, 0xFF ].pack("C*")
    ukey << @parent.file_identifier
    @parent.encryption_key = Digest::MD5.hexdigest(ukey)[0...5]

    @parent.arc4.prepare(@parent.encryption_key)

    @user_info = @parent.arc4.encrypt(PAD)
  end

  def to_s
    res = "\n#{@oid} 0 obj\n<<\n/Filter /Standard\n"
    res << "/V 1\n/R 2\n"
    res << "/O (#{PDF::Writer.escape(@owner_info)})\n"
    res << "/U (#{PDF::Writer.escape(@user_info)})\n"
    res << "/P #{(((@perms ^ 255) + 1) * -1)}\n"
    res << ">>\nendobj\n"
    res
  end
end
