class MeetingMembershipsController < ApplicationController
  def show
    if params[:person_id]
      @person = Person.find(params[:person_id])
      @meeting_memberships = @person.meeting_memberships
      @meeting_membership = MeetingMembership.new(person_id: params[:person_id])
      @meeting_membership_types = MeetingMembershipType.all()
      @meetings = Meeting.all()
    end
  end

  def create
    unless @logged_in.admin?(:manage_meeting_memberships)
      render html: t('not_authorized'), layout: true, status: 401
      return
    end

    @meeting_membership = MeetingMembership.new(meeting_membership_params)
    if @meeting_membership.save
      if @logged_in.admin?(:manage_meeting_memberships)
        flash[:notice] = 'Meeting Membership Created'
        redirect_to request.referrer
      end
    else
      render action: 'new'
    end
  end

  def meeting_membership_attributes
    %i(person_id meeting_id meeting_membership_type_id) if @logged_in.admin?(:manage_meeting_memberships)
  end

  def meeting_membership_params
    params.permit(*meeting_membership_attributes)
  end
end