class PersonSweeper < ActionController::Caching::Sweeper
  observe Person

  def after_save(record)
    expire_fragment(%r{views/people/#{record.id}_})
    record.stream_items.all.each do |stream_item|
      expire_fragment(%r{views/stream/stream_items/#{stream_item.id}_})
    end
    record.groups.all.each do |group|
      expire_fragment(:controller => 'groups', :action => 'show', :id => group.id)
    end
  end

  alias_method :after_destroy, :after_save

end
