class SearchesController < ApplicationController

  MAX_SELECT_PEOPLE = 10
  MAX_SELECT_FAMILIES = 10

  def show
    # A search should be referencable by URI, thus "show" makes sense;
    # though "create" makes more sense from a resource standpoint.
    # We'll do both. :-)
    if params_without_action.any?
      create
    else
      redirect_to new_search_path
    end
  end

  def new
  end

  def create
    if params[:family_name].present? and params[:family_barcode_id].present?
      @search = Search.new(params.merge(source: :family))
      @families = @search.results.page(params[:page])
    else
      @search = Search.new(params)
      @people = @search.results.page(params[:page])
    end
    respond_to do |format|
      format.html do
        if false and @people.length == 1 and (params[:name] or params[:quick_name])
          redirect_to person_path(id: @people.first)
        else
          render action: 'create'
        end
      end
      format.js do
        if params[:auto_complete]
          @people = @people[0..MAX_SELECT_PEOPLE]
          render partial: 'auto_complete'
        elsif params[:select_person]
          @more = @people.length > MAX_SELECT_PEOPLE
          @people = @people[0...MAX_SELECT_PEOPLE]
        elsif params[:select_family]
          @more = @families.length > MAX_SELECT_FAMILIES
          @families = @families.to_a[0..MAX_SELECT_FAMILIES]
        end
      end
    end
  end

end
