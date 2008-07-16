class FamilySweeper < ActionController::Caching::Sweeper
  observe Family

  def after_save(record)
    record.people.each do |person|
      # expire_fragment allows regexps, while expire_action does not
      expire_fragment(%r{views/people/#{record.id}_})
    end
  end
  
  alias_method :after_destroy, :after_save
  
end
