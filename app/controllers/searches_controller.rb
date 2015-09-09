class SearchesController < ApplicationController
  MAX_SELECT_PEOPLE = 10
  MAX_SELECT_FAMILIES = 10

  before_action :fetch_family, if: -> { params[:family_id] }

  def show
    create
  end

  def new
    redirect_to search_path
  end

  def create
    create_search
    respond_to do |format|
      format.html do
        if @people.length == 1 && params[:quick_name]
          redirect_to @people.first
        else
          render action: 'create'
        end
      end
      format.js do
        render_js
      end
    end
  end

  private

  def create_search
    if params[:family_name].present? || params[:family_barcode_id].present?
      create_family_search
    else
      @search = PersonSearch.new(params)
      @people = @search.results.page(params[:page])
    end
  end

  def create_family_search
    @search = FamilySearch.new(params)
    @families = @search.results.page(params[:page])
  end

  def render_js
    if params[:auto_complete]
      @people = @people[0..MAX_SELECT_PEOPLE]
      render partial: 'auto_complete'
    elsif params[:select_person]
      @more = @people.length > MAX_SELECT_PEOPLE
      @people = @people[0...MAX_SELECT_PEOPLE]
    elsif params[:select_family]
      @families ||= []
      @more = @families.length > MAX_SELECT_FAMILIES
      @families = @families.to_a[0..MAX_SELECT_FAMILIES]
    end
  end

  def fetch_family
    @family = Family.find(params[:family_id])
    fail StandardError unless @logged_in.can_update?(@family)
  end
end
