class FamilySweeper < ActionController::Caching::Sweeper
  observe Family

  def after_save(record)
    record.people.each do |person|
      expire_action(:controller => 'people', :action => 'show', :id => person.id)
    end
  end
  
  alias_method :after_destroy, :after_save
  
end
