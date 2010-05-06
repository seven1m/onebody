class PageSweeper < ActionController::Caching::Sweeper
  observe Page

  def after_save(record)
    expire_action("pages/#{record.path}")
  end

  alias_method :after_destroy, :after_save

end
