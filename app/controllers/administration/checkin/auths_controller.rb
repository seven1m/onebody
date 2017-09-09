class Administration::Checkin::AuthsController < ApplicationController
  before_action :only_admins

  def index
    unless params[:group_id] && params[:code]
      render plain: 'must specify group_id and code'
      return
    end
    @people = Group.find(params[:group_id]).people.order('last_name, first_name').to_a
    if params[:max_age]
      @people.reject! { |p| p.adult? || (p.years_of_age && p.years_of_age > params[:max_age].to_i) }
    end
    @groups = {}
    @people.each do |person|
      next unless (group = person.classes.to_s.split(',').detect do |c|
        c =~ Regexp.new('^' + params[:code].scan(/[a-z0-9]+/i).join)
      end) && group =~ /\[(.+)\]/
      @groups[Regexp.last_match(1)] ||= []
      @groups[Regexp.last_match(1)] << person
    end
    render layout: false if params[:print]
  end

  private

  def only_admins
    unless @logged_in.admin?(:manage_checkin)
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
