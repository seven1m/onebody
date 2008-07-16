class PersonSweeper < ActionController::Caching::Sweeper
  observe Person

  def after_save(record)
    # expire_fragment allows regexps, while expire_action does not
    expire_fragment(%r{views/people/#{record.id}_})
  end
  
  alias_method :after_destroy, :after_save
  
end
