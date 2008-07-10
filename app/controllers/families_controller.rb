class FamiliesController < ApplicationController
  
  def show
    @family = Family.find(params[:id])
    @people = @family.people.all.select { |p| @logged_in.can_see? p }
    unless @logged_in.can_see?(@family)
      render :text => 'Family not found.', :status => 404
    end
  end
  
  before_filter :can_edit?, :only => %w(new create edit update)
  
  def new
    @family = Family.new
  end
  
  def create
    @family = Family.new
    @family.update_attributes params[:family]
    redirect_back
  end
  
  def edit
    @family = Family.find(params[:id])
  end

  def update
    @family = Family.find(params[:id])
    @family.update_attributes params[:family]
    redirect_back
  end
  
  private

  def can_edit?
    if Setting.get(:features, :standalone_use) and @logged_in.admin?(:edit_profiles)
      true
    else
      render :text => 'Not authorized or feature unavailable.', :status => 401
      false
    end
  end
end
