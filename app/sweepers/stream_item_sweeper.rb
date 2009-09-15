class StreamItemSweeper < ActionController::Caching::Sweeper
  observe StreamItem

  def after_save(record)
    expire_fragment(%r{views/people/#{record.person_id}_})
    expire_fragment(%r{views/people/#{record.wall_id}_}) if record.wall_id
    expire_fragment(%r{views/stream/stream_items/#{record.id}_})
  end
  
  alias_method :after_destroy, :after_save
  
end
