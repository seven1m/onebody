# For use with 'Edge Rails'
class ActionController::Routing::RouteSet::Mapper

  # For mounting a page to a path
  def comatose_root( path, options={} )
    opts = {
      :index      => '',
      :layout     => 'comatose_content',
      :use_cache  => 'true',
      :cache_path => nil,
      :named_route=> nil
    }.merge(options)
    # Ensure the controller is aware of the mount point...
    Comatose.add_mount_point(path, opts)
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

  # For mounting the admin
  def comatose_admin( path='comatose_admin', options={} )
    opts = {
      :controller  => 'comatose_admin',
      :named_route => 'comatose_admin'
    }.merge(options)
    route_name = opts.delete(:named_route)
    named_route( route_name, "#{path}/:action/:id", opts )
  end
    
  def method_missing( name, *args, &proc )
    if name.to_s.starts_with?( 'comatose_' )
      opts = (args.last.is_a?(Hash)) ? args.pop : {}
      opts[:named_route] = name.to_s #[9..-1]
      comatose_root( *(args << opts) )
    else
      super unless args.length >= 1 && proc.nil?
      @set.add_named_route(name, *args)
    end
  end
end
