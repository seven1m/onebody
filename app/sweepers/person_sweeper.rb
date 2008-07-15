class PersonSweeper < ActionController::Caching::Sweeper
  observe Person

  def after_save(record)
    expire_action(:controller => 'people', :action => 'show', :id => record.id)
  end
  
  alias_method :after_destroy, :after_save
  
end
