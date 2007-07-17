# $Id: cache.rb,v 1.4 2004/04/01 09:44:31 ianmacd Exp $

require 'fileutils'
require 'md5'

module Amazon
  module Search

    # This class is used internally by Ruby/Amazon. You should never need
    # to manually instantiate it or invoke most of the methods here. The only
    # exceptions are #flush_all and #flush_expired.
    #
    class Cache

      # Exception class for bad cache paths.
      #
      class PathError < StandardError; end

      # Length of one day in seconds
      #
      ONE_DAY = 86400	# :nodoc:

      # Age in days below which to consider cache files valid.
      #
      MAX_AGE = 1.0   

      def initialize(path)
	::FileUtils::mkdir_p(path) unless File.exists?(path)

	unless File.directory?(path)
	  raise PathError, "cache path #{path} is not a directory"
	end

	unless File.readable?(path)
	  raise PathError, "cache path #{path} is not readable"
	end

	unless File.writable?(path)
	  raise PathError, "cache path #{path} is not writable"
	end

	@path = path
      end

      # Determine whether or not the the response to a given URL is cached.
      # Returns +true+ or +false+.
      #
      def cached?(url)
	digest = Digest::MD5.hexdigest(url)

	cache_files = Dir.glob(File.join(@path, '*')).map do |d|
	  File.basename(d)
	end

	return cache_files.include?(digest) &&
	 (Time.now - File.mtime(File.join(@path, digest))) / ONE_DAY <= MAX_AGE
      end

      # Retrieve the cached response associated with _url_.
      #
      def get_cached(url)
	digest = Digest::MD5.hexdigest(url)
	cache_file = File.join(@path, digest)

	return nil unless File.exist? cache_file

	Amazon::dprintf("Fetching %s from cache...\n", digest)
	File.open(File.join(cache_file)).readlines.to_s
      end

      # Cache the data from _contents_ and associate it with _url_.
      #
      def cache(url, contents)

	digest = Digest::MD5.hexdigest(url)
	cache_file = File.join(@path, digest)

	Amazon::dprintf("Caching %s...\n", digest)
	File.open(cache_file, 'w') { |f| f.puts contents }
      end

      # This method flushes all files from the cache directory specified
      # in the object's <i>@path</i> variable.
      #
      def flush_all
	FileUtils.rm Dir.glob(File.join(@path, '*'))
      end

      # This method flushes expired files from the cache directory specified
      # in the object's <i>@path</i> variable.
      #
      def flush_expired
	expired_files = Dir.glob(File.join(@path, '*')).find_all do |f|
	  (now - File.mtime(f)) / ONE_DAY > MAX_AGE
	end

	FileUtils.rm expired_files
      end

    end
  end
end
