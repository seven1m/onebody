class PrayerRequestsController < ApplicationController

  def index
    @group = Group.find(params[:group_id])
    if params[:answered]
      @reqs = @group.prayer_requests.paginate(conditions: "answer != '' and answer is not null", order: 'created_at desc', page: params[:page])
    else
      @reqs = @group.prayer_requests.paginate(order: 'created_at desc', page: params[:page])
    end
  end

  def show
    @req = PrayerRequest.find(params[:id])
    unless @logged_in.can_see?(@req)
      render text: t('prayer.not_found'), layout: true, status: 404
    end
  end

  def new
    @group = Group.find(params[:group_id])
    if @logged_in.member_of?(@group)
      @req = @group.prayer_requests.new(person_id: @logged_in.id)
    else
      render text: t('prayer.cant_post'), layout: true, status: 401
    end
  end

  def create
    @group = Group.find(params[:group_id])
    if @logged_in.member_of?(@group)
      params[:prayer_request][:answered_at] = Date.parse(params[:prayer_request][:answered_at]) rescue nil
      @req = @group.prayer_requests.build(params[:prayer_request])
      @req.person = @logged_in
      if @req.save
        redirect_to group_path(@req.group, anchor: 'prayer')
      else
        new; render action: 'new'
      end
    else
      render text: t('prayer.cant_post'), layout: true, status: 401
    end
  end

  def edit
    @group = Group.find(params[:group_id])
    @req = PrayerRequest.find(params[:id])
    unless @logged_in.can_edit?(@req)
      render text: t('prayer.cant_edit'), layout: true, status: 401
    end
  end

  def update
    @group = Group.find(params[:group_id])
    @req = PrayerRequest.find(params[:id])
    if @logged_in.can_edit?(@req)
      params[:prayer_request][:answered_at] = Date.parse(params[:prayer_request][:answered_at]) rescue nil
      if @req.update_attributes(params[:prayer_request])
        redirect_to group_path(@req.group, anchor: 'prayer')
      else
        edit; render action: 'edit'
      end
    else
      render text: t('prayer.cant_edit'), layout: true, status: 401
    end
  end

  def destroy
    @group = Group.find(params[:group_id])
    @req = PrayerRequest.find(params[:id])
    if @logged_in.can_edit?(@req)
      @req.destroy
      redirect_to group_path(@group, anchor: 'prayer')
    else
      render text: t('prayer.cant_delete'), layout: true, status: 401
    end
  end
end
