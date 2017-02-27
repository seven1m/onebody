class SearchesController < ApplicationController

  MAX_SELECT_PEOPLE = 10
  MAX_SELECT_FAMILIES = 10

  before_filter :get_family, if: -> { params[:family_id] }

  def show
    create
  end

  def new
    redirect_to search_path
  end

  def create
    if params[:family_name].present? or params[:family_barcode_id].present?
      if params[:family_name] =~ /^\d+$/
        params[:family_barcode_id] = params.delete(:family_name)
      end
      @search = Search.new(params.merge(source: :family))
      @families = @search.results.page(params[:page])
    else
      @search = Search.new(params)
      @people = @search.results.page(params[:page])
    end
    respond_to do |format|
      format.html do
        render action: 'create'
      end
      format.js do
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
    end
  end

  private

  def get_family
    @family = Family.find(params[:family_id])
    raise StandardError unless @logged_in.can_update?(@family)
  end

end
