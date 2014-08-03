class Administration::Checkin::AuthsController < ApplicationController

  before_filter :only_admins

  def index
    unless params[:group_id] and params[:code]
      render :text => 'must specify group_id and code'
      return
    end
    @people = Group.find(params[:group_id]).people.order('last_name, first_name').to_a
    if params[:max_age]
      @people.reject! { |p| p.adult? or (p.years_of_age and p.years_of_age > params[:max_age].to_i) }
    end
    @groups = {}
    @people.each do |person|
      if group = person.classes.to_s.split(',').detect { |c|
        c =~ Regexp.new('^' + params[:code].scan(/[a-z0-9]+/i).join)
      } and group =~ /\[(.+)\]/
        @groups[$1] ||= []
        @groups[$1] << person
      end
    end
    render :layout => false if params[:print]
  end

  private

    def only_admins
      unless @logged_in.admin?(:manage_checkin)
        render :text => 'You must be an administrator to use this section.', :layout => true, :status => 401
        return false
      end
    end

    def feature_enabled?
      unless Setting.get(:features, :checkin)
        render :text => 'This feature is unavailable.', :layout => true
        false
      end
    end

end
