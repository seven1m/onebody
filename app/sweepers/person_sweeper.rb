class PersonSweeper < ActionController::Caching::Sweeper
  observe Person

  def expire_group_members(record)
    record.groups.all.each do |group|
      expire_fragment(:controller => 'groups', :action => 'show', :id => group.id, :fragment => 'members')
    end
  end

  def expire_stream_items(record)
    record.stream_items.all.each do |stream_item|
      stream_item.expire_caches
    end
  end

  def after_save(record)
    expire_group_members(record)
    expire_stream_items(record)
  end

  def after_destroy(record)
    expire_group_members(record)
    expire_stream_items(record)
  end

end
