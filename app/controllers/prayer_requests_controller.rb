class PrayerRequestsController < ApplicationController

  load_and_authorize_parent :group, optional: true
  load_and_authorize_resource

  def index
    if @logged_in.member_of?(@group)
      if params[:answered]
        @reqs = prayer_requests.where("coalesce(answer, '') != ''").order(created_at: :desc).page(params[:page])
      else
        @reqs = prayer_requests.order(created_at: :desc).page(params[:page])
      end
    else
      render text: t('not_authorized'), layout: true, status: :forbidden
    end
  end

  def show
  end

  def new
  end

  def create
    if @prayer_request.save
      redirect_to group_prayer_requests_path(@group)
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    if @prayer_request.update_attributes(prayer_request_params)
      redirect_to group_prayer_request_path(@group, @prayer_request)
    else
      render action: 'edit'
    end
  end

  def destroy
    @prayer_request.destroy
    redirect_to group_prayer_requests_path(@group)
  end

  private

  def prayer_request_params
    params.require(:prayer_request).permit(:person_id, :request, :answer, :answered_at)
  end
end
