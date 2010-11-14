class PersonSweeper < ActionController::Caching::Sweeper
  observe Person

  def expire_group_members(record)
    record.groups.all.each do |group|
      expire_fragment(:controller => 'groups', :action => 'show', :id => group.id, :fragment => 'members')
    end
  end

  def after_save;    expire_group_members; end
  def after_destroy; expire_group_members; end

end
