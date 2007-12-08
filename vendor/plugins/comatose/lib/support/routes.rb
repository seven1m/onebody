# For Rails 1.1 - DEPRECATED


# Adds the comatose_root mapping support to the Rails Routset
class ActionController::Routing::RouteSet

  def comatose_root( path, options={} )
    opts = {
      :index      => '',
      :layout     => 'comatose_content',
      :use_cache  => 'true',
      :cache_path => nil,
      :named_route=> nil
    }.merge(options)
    # Ensure the controller is aware of the mount point...
    ComatoseController.add_mount_point(path, opts)
    # Add the route...
    opts[:controller] = 'comatose'
    opts[:action] ='show'
    route_name = opts.delete(:named_route)
    unless route_name.nil?
      named_route( route_name, "#{path}/*page", opts )
    else
      if opts[:index] == '' # if it maps to the root site URI, name it comatose_root
        named_route( 'comatose_root', "#{path}/*page", opts )
      else
        connect( "#{path}/*page", opts )
      end
    end
  end
  
  def method_missing( name, *args )
    if name.to_s.starts_with?( 'comatose_' )
      opts = (args.last.is_a?(Hash)) ? args.pop : {}
      opts[:named_route] = name.to_s #[9..-1]
      comatose_root( *(args << opts) )
    else
      (1..2).include?(args.length) ? named_route(name, *args) : super(name, *args)
    end
  end

end
