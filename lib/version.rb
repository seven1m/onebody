class Version
  include Comparable

  attr_accessor :major, :minor, :patch, :special

  def self.from_string(string)
    Version.new(*string.split(/\.|\-/))
  end

  def initialize(major, minor, patch, special = nil)
    @major = major
    @minor = minor
    @patch = patch
    @special = special
  end

  def <=>(other_version)
    to_a <=> other_version.to_a
  end

  def to_a
    [@major, @minor, @patch, @special || 'zzz']
  end

  def to_s
    v = [@major, @minor, @patch].join('.')
    v += "-#{@special}" if @special
    v
  end
end
