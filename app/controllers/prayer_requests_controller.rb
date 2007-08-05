class PrayerRequestsController < ApplicationController
  def edit
    @req = params[:id] ? PrayerRequest.find(params[:id]) : PrayerRequest.new(:person_id => @logged_in.id, :group_id => params[:group_id])
    raise 'Unauthorized' unless @logged_in.can_edit?(@req)
    if request.post?
      if params[:prayer_request][:answered_at].to_s.empty?
        params[:prayer_request][:answered_at] = nil
      else
        params[:prayer_request][:answered_at] = Date.parse(params[:prayer_request][:answered_at])
      end
      if @req.update_attributes params[:prayer_request]
        redirect_to @req.group ? group_url(:id => @req.group, :anchor => 'prayerrequests') : prayer_request_url(:id => @req)
      else
        flash[:warning] = @req.errors.full_messages.join('; ')
      end
    end
  end
  
  def view
    @req = PrayerRequest.find params[:id]
    raise 'Unauthorized' unless @logged_in.can_see? @req
  end
  
  def delete
    @req = PrayerRequest.find params[:id]
    if @req.person == @logged_in or (@req.group and @req.group.admin? @logged_in)
      @req.destroy
    end
    redirect_to params[:return_to] ? params[:return_to] + '#prayerrequests' : group_url(:id => @req.group, :anchor => 'prayerrequests')
  end
  
  def answered
    @group = Group.find params[:id]
    @reqs = @group.prayer_requests.find(:all, :conditions => "answer != '' and answer is not null", :order => 'created_at desc')
  end
end
