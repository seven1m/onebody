class MessageSweeper < ActionController::Caching::Sweeper
  observe Message

  def after_save(record)
    expire_fragment(%r{views/people/#{record.wall_id}_}) if record.wall_id
  end
  
  alias_method :after_destroy, :after_save
  
end
