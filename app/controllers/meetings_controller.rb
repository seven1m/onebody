class MeetingsController < ApplicationController
  def index
    @meetings = Meeting.all
    respond_to do |format|
      format.html
      format.js { render plain: @meetings.to_json }
    end
  end

  def show
    @meeting = Meeting.find(params[:id])
  end

  def new
    @meeting = Meeting.new
  end

  def create
    @meeting = Meeting.new(meeting_params)
    if @meeting.save
      flash[:notice] = 'Meeting Saved'
      redirect_to @meeting
    else
      render action: 'new'
    end
  end

  def edit
    @meeting = Meeting.find(params[:id])
  end

  def update
    @meeting = Meeting.find(params[:id])
    if @meeting.update_attributes(meeting_params)
      flash[:notice] = t('Changes_saved')
      redirect_to @meeting
    else
      render action: 'edit'
    end
  end

  def meeting_attributes
    %i(name)
  end

  def meeting_params
    params.require(:meeting).permit(*meeting_attributes)
  end
end
