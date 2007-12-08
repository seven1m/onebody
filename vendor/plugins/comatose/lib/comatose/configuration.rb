module Comatose

  def self.config
    @@config ||= Configuration.new
  end

  def self.configure(&block)
    raise "#configure must be sent a block" unless block_given?
    yield config
    config.validate!
  end
  
  # All of the 'mount' points for Comatose
  def self.mount_points
    @@mount_points ||= []
  end

  # Adds a 'mount' point to the list of known roots...
  def self.add_mount_point(path, info={:index=>''})
    path = "/#{path}" unless path.starts_with? '/'
    info[:root]=path
    mount_points << info
  end

  class Configuration

    attr_accessor_with_default :admin_title,          'Comatose'
    attr_accessor_with_default :admin_includes,       []
    attr_accessor_with_default :admin_helpers,        []
    attr_accessor_with_default :admin_sub_title,      'The Micro CMS'
    attr_accessor_with_default :content_type,         'utf-8'
    attr_accessor_with_default :default_filter,       'Textile'
    attr_accessor_with_default :default_processor,    :liquid
    attr_accessor_with_default :default_tree_level,   2
    attr_accessor_with_default :disable_caching,      false
    attr_accessor_with_default :hidden_meta_fields,   []
    attr_accessor_with_default :helpers,              []
    attr_accessor_with_default :includes,             []

    # A 'blockable' setters
    blockable_attr_accessor    :authorization
    blockable_attr_accessor    :admin_authorization
    blockable_attr_accessor    :admin_get_author
    blockable_attr_accessor    :admin_get_root_page
    blockable_attr_accessor    :after_setup

    def initialize
      # Default procs for blockable attrs....
      @authorization       = Proc.new { true }
      @admin_authorization = Proc.new { true }
      @admin_get_author    = Proc.new { request.env['REMOTE_ADDR'] }
      @admin_get_root_page = Proc.new { Comatose::Page.root }
      @after_setup         = Proc.new { true }
    end
    
    def validate!
      # Rips through the config and validates it's, er, valid
      raise ConfigurationError.new "admin_get_author must be a Proc or Symbol" unless @admin_get_author.is_a? Proc or @admin_get_author.is_a? Symbol
      raise ConfigurationError.new  "admin_authorization must be a Proc or Symbol" unless @admin_authorization.is_a? Proc or @admin_authorization.is_a? Symbol
      raise ConfigurationError.new  "authorization must be a Proc or Symbol" unless @authorization.is_a? Proc or @authorization.is_a? Symbol
      true
    end
    
    class ConfigurationError < StandardError; end
    
  end

end
