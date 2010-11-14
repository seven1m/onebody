class GroupSweeper < ActionController::Caching::Sweeper
  observe Group

  def after_save(record)
    expire_fragment(%r{groups/#{record.id}})
  end

  alias_method :after_destroy, :after_save

end
