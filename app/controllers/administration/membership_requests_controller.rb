class Administration::MembershipRequestsController < ApplicationController
  before_action :only_admins

  def index
    @reqs_by_group = MembershipRequest.all.to_a.group_by(&:group)
  end

  private

  def only_admins
    unless @logged_in.admin?(:manage_groups)
      render plain: t('only_admins'), layout: true, status: 401
      false
    end
  end
end
