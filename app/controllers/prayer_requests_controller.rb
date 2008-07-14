class PrayerRequestsController < ApplicationController

  def index
    @group = Group.find(params[:group_id])
    if params[:answered]
      @reqs = @group.prayer_requests.find(:all, :conditions => "answer != '' and answer is not null", :order => 'created_at desc')
    else
      @reqs = @group.prayer_requests.all(:order => 'created_at desc')
    end
  end

  def show
    @req = PrayerRequest.find(params[:id])
    unless @logged_in.can_see?(@req)
      render :text => 'Prayer Request not found.', :layout => true, :status => 404
    end
  end

  def new
    @group = Group.find(params[:group_id])
    if @logged_in.member_of?(@group)
      @req = @group.prayer_requests.new(:person_id => @logged_in)
    else
      render :text => 'You cannot post a prayer request in this group because you are not a member.', :layout => true, :status => 401
    end
  end

  def create
    @group = Group.find(params[:group_id])
    if @logged_in.member_of?(@group)
      params[:prayer_request][:answered_at] = Date.parse(params[:prayer_request][:answered_at]) rescue nil
      @req = @group.prayer_requests.create(params[:prayer_request].merge(:person_id => @logged_in.id))
      unless @req.errors.any?
        redirect_to group_path(@req.group, :anchor => 'prayerrequests')
      else
        new; render :action => 'new'
      end
    else
      render :text => 'You cannot post a prayer request in this group because you are not a member.', :layout => true, :status => 401
    end
  end
  
  def edit
    @group = Group.find(params[:group_id])
    @req = PrayerRequest.find(params[:id])
    unless @logged_in.member_of?(@group) and @logged_in.can_edit?(@req)
      render :text => 'You cannot edit this prayer request.', :layout => true, :status => 401
    end
  end
  
  def update
    @group = Group.find(params[:group_id])
    @req = PrayerRequest.find(params[:id])
    if @logged_in.member_of?(@group) and @logged_in.can_edit?(@req)
      params[:prayer_request][:answered_at] = Date.parse(params[:prayer_request][:answered_at]) rescue nil
      if @req.update_attributes(params[:prayer_request])
        redirect_to group_path(@req.group, :anchor => 'prayerrequests')
      else
        edit; render :action => 'edit'
      end
    else
      render :text => 'You cannot edit this prayer request.', :layout => true, :status => 401
    end
  end
    
  def destroy
    @group = Group.find(params[:group_id])
    @req = PrayerRequest.find(params[:id])
    if @logged_in.member_of?(@group) and @logged_in.can_edit?(@req)
      @req.destroy
      redirect_to group_path(@group, :anchor => 'prayerrequests')
    else
      render :text => 'You cannot delete this prayer request.', :layout => true, :status => 401
    end
  end
end
