module SearchesHelper

  def show_birthdays?
    return false unless params[:birthday]
    params[:birthday][:month].present? ||
    params[:birthday][:day].present?
  end

end
