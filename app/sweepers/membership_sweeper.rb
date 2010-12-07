class MembershipSweeper < ActionController::Caching::Sweeper
  observe Membership

  def after_save(record)
    expire_fragment(%r{groups/#{record.group_id}})
  end

  alias_method :after_destroy, :after_save

end
