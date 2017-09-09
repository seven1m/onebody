class Administration::Checkin::DashboardsController < ApplicationController
  before_action :only_admins

  def show
  end

  private

  def only_admins
    unless @logged_in.admin?(:manage_checkin) || @logged_in.admin?(:assign_checkin_cards)
      render html: 'You must be an administrator to use this section.', layout: true, status: 401
      false
    end
  end

  def feature_enabled?
    unless Setting.get(:features, :checkin)
      render html: 'This feature is unavailable.', layout: true
      false
    end
  end
end
