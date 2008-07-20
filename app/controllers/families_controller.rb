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
    @family = Family.create(params[:family])
    redirect_to @family
  end
  
  def edit
    @family = Family.find(params[:id])
  end

  def update
    @family = Family.find(params[:id])
    @family.update_attributes(params[:family])
    redirect_to @family
  end
  
  private

  def can_edit?
    unless @logged_in.admin?(:edit_profiles)
      render :text => 'Not authorized or feature unavailable.', :layout => true, :status => 401
      return false
    end
  end
end
