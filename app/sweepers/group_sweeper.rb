class GroupSweeper < ActionController::Caching::Sweeper
  observe Group

  def after_save(record)
    expire_fragment(:controller => 'groups', :action => 'show', :id => record.id)
  end

  alias_method :after_destroy, :after_save

end
