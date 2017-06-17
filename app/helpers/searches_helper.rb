module SearchesHelper
  def show_birthdays?
    return false unless params[:birthday]
    params[:birthday][:month].present? ||
      params[:birthday][:day].present?
  end

  def show_testimonies?
    params[:testimony].present?
  end

  def types_for_select
    options_from_i18n('search.form.types').to_a +
      (Setting.get(:features, :custom_person_type) ? Person.custom_types : [])
  end

  def search_path(*args)
    if params[:controller] == 'searches' && params[:family_id] && @family
      family_search_path(*args)
    else
      super
    end
  end
end
