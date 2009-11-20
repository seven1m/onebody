# ---------------------------------------------------------------------------
# This implements a specialization of the standard Capistrano RemoteCache
# deployment strategy. The most significant difference between this strategy
# and the RemoteCache is the way the cache is copied to the final release
# directory: it uses the bundled "copy.rb" script to use hard links to the
# files instead of actually copying, so the copy stage is much, much faster.
# ---------------------------------------------------------------------------
# This file is distributed under the terms of the MIT license by 37signals,
# LLC, and is copyright (c) 2008 by the same. See the LICENSE file distributed
# with this file for the complete text of the license.
# ---------------------------------------------------------------------------
require 'capistrano/recipes/deploy/strategy/remote_cache'

class Capistrano::Deploy::Strategy::FastRemoteCache < Capistrano::Deploy::Strategy::RemoteCache
  def check!
    super.check do |d|
      d.remote.command(configuration.fetch(:ruby, "ruby"))
      d.remote.directory(bin_path)
      d.remote.file(File.join(bin_path, "copy.rb"))
    end
  end

  def setup!
    run "mkdir -p #{bin_path}"
    upload(File.join(File.dirname(__FILE__), "utilities", "copy.rb"), File.join(bin_path, "copy.rb"))
  end

  def prepare!
    update_repository_cache
  end

  private

    def bin_path
      @bin_path ||= File.join(configuration[:shared_path], "bin")
    end

    def copy_repository_cache
      logger.trace "copying the cached version to #{configuration[:release_path]}"
      ruby = configuration.fetch(:ruby, "ruby")
      excludes = Array(configuration[:copy_exclude]).join(" ")
      run "#{ruby} #{File.join(bin_path, 'copy.rb')} #{repository_cache} #{configuration[:release_path]} #{excludes} && #{mark}"
    end
end
