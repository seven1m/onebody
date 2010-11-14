class FamilySweeper < ActionController::Caching::Sweeper
  observe Family

  def expire_group_members(record)
    record.people.each do |person|
      PersonSweeper.instance.expire_group_members(person)
    end
  end

  def after_save;    expire_group_members; end
  def after_destroy; expire_group_members; end

end
