module ActionController
  module Caching
    module Fragments
      # expire a cache key only if the block returns true or
      # if the age of the fragment is more than the specified age argument.
      def expire_fragment_by_mtime(key, age=nil, &block)
        block = Proc.new { |m| m < age.ago } unless block_given?
        if (m = cache_store.mtime(fragment_cache_key(key))) and block.call(m)
          expire_fragment(key)
        end
      end
    end
    module Actions
      module ClassMethods
        # adds an option :for
        # caches_action :show, :for => 2.hours, :cache_path => ...
        # :cache_path is required, unfortunately
        def caches_action_with_for(*actions)
          original_actions = actions.clone
          options = actions.extract_options!
          if for_time = options.delete(:for)
            cache_path = options[:cache_path]
            before_filter do |controller|
              cache_path = cache_path.call(controller) if cache_path.respond_to?(:call)
              controller.expire_fragment_by_mtime(cache_path, for_time)
            end
          end
          caches_action_without_for(*original_actions)
        end
        alias_method_chain :caches_action, :for
      end
    end
  end
end

# Add a method to grab the last modified time of the cache key.
# If you use a store other than the FileStore, you'll need to add
# a method like this to your store.
module ActiveSupport
  module Cache
    class FileStore
      def mtime(name)
        File.mtime(real_file_path(name)) rescue nil
      end
    end
  end
end

