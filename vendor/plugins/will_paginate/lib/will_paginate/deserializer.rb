module WillPaginate
  # A mixin for ActiveResource::Base. Provides +per_page+ class method
  # and hooks things up to provide paginating finders.
  #
  # Find out more in WillPaginate::Deserializer::ClassMethods
  #  
  module Deserializer

    def self.included(base)
      base.extend ClassMethods
      class << base
        alias_method_chain :instantiate_collection, :collection
        define_method(:per_page) { 30 } unless respond_to?(:per_page)        
      end
    end
    
    # = Paginating finders for ActiveResource models
    # 
    # WillPaginate adds +paginate+, +per_page+ and other methods to
    # ActiveResource::Base class methods and associations. 
    # 
    # In short, paginating finders are equivalent to ActiveResource finders; the
    # only difference is that we start with paginate instead of <tt>find</tt>, exclude the first <tt>:all</tt> parameter optionally, and
    # the <tt>:params</tt> and its containing <tt>:page</tt> parameter are both required:
    #
    #   @posts = Post.paginate :all, :params => {:page => params[:page], :order => 'created_at DESC'}
    # 
    # In paginating finders, "all" is implicit. There is no sense in paginating
    # a single record, right? So, you can drop the <tt>:all</tt> argument:
    # 
    #   Post.paginate(:params => {:page => params[:page]}) =>  Post.find(:all, :params => {:page => params[:page]})
    #
    # == The importance of the <tt>:params</tt> parameter
    #
    # In ActiveResource, all parameters in <tt>:params</tt> just get 
    # appeneded to the request url as the query string. It is up to the server
    # to correctly snatch the options out of the params and do something
    # meaningful with them. 
    #
    # This is especially important for the <tt>:page</tt> and <tt>:per_page</tt>
    # parameters, as they are indicators for the server to paginate. If the server
    # does not use WillPaginate's ActiveRecord.paginate and returns a standard
    # Array from <tt>to_xml</tt>, then that index action is likely to return all 
    # records. ActiveResource's paginate method is smart enough to paginate the resultset
    # for Arrays returned by the server, but realize that grabbing all records constantly
    # will be performance intensive. However, if the server uses ActiveResource.paginate
    # then <tt>to_xml</tt> will return in a special format that will properly be
    # parsed into a plain vanilla WillPaginate::Collection object that works with all 
    # the standard view helpers.
    module ClassMethods
      # This is the main paginating finder.
      #
      # == Special parameters for paginating finders
      # * <tt>:params => :page</tt> -- REQUIRED, but defaults to 1 if false or nil
      # * <tt>:params => :per_page</tt> -- defaults to <tt>CurrentModel.per_page</tt> (which is 30 if not overridden)
      #
      # All other options (ie: +from+) work as they normally would in <tt>ActiveResource.find(:all)</tt>.
      def paginate(*args)
        options = wp_parse_options(args.pop)
        results = find(:all, options)
        results.is_a?(WillPaginate::Collection) ? results : results.paginate(:page => options[:params][:page], :per_page => options[:params][:per_page])
      end
      
      # Takes the format that Hash.from_xml produces out of an unknown type
      # (produced by WillPaginate::Collection#to_xml_with_collection_type), 
      # parses it into a WillPaginate::Collection,
      # and forwards the result to the former +instantiate_collection+ method.
      # It only does this for hashes that have a :type => "collection".
      def instantiate_collection_with_collection(collection, prefix_options = {})
        if collection.is_a?(Hash) && collection["type"] == "collection"
          collectables = collection.values.find{|c| c.is_a?(Hash) || c.is_a?(Array) }
          collectables = [collectables].compact unless collectables.kind_of?(Array)
          instantiated_collection = WillPaginate::Collection.create(collection["current_page"], collection["per_page"], collection["total_entries"]) do |pager|
            pager.replace instantiate_collection_without_collection(collectables, prefix_options)
          end          
        else
          instantiate_collection_without_collection(collection, prefix_options)
        end        
      end
    
    protected
      
      def wp_parse_options(options) #:nodoc:
        raise ArgumentError, 'parameter hash expected' unless options.respond_to? :symbolize_keys
        options = options.symbolize_keys
        raise ArgumentError, ':params hash parameter required' unless options.key?(:params) && options[:params].respond_to?(:symbolize_keys)
        options[:params] = options[:params].symbolize_keys
        raise ArgumentError, ':params => :page parameter required' unless options[:params].key? :page                      

        options[:params][:per_page] ||= per_page
        options[:params][:page] ||= 1
        options
      end
    end        
    
  end  
end