class FamilyUpdater < Updater
  def params=(p)
    super
    @family_id = @id
    @id = nil
  end

  def person
    Person.logged_in
  end

  def family
    @family ||= Family.find(@family_id)
  end
end
