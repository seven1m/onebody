class SearchesController < ApplicationController

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
    params.reject_blanks!
    @search = Search.new_from_params(params)
    @people = @search.query(params[:page])
    @pages, @count = @search.pages, @search.count
    @show_birthdays = params[:birthday_month] or params[:birthday_day]
    @service_categories = Person.service_categories if @search.show_services
    respond_to do |wants|
      wants.html do
        if @people.length == 1 and (params[:name] or params[:quick_name])
          redirect_to person_path(:id => @people.first)
        else
          render :action => 'new'
        end
      end
      wants.js do
        render :update do |page|
          if params[:select_person]
            @people = @people[0..MAX_SELECT_PEOPLE]
            page.replace_html 'results', :partial => 'select_person'
            page.show 'add_member'
          else
            page.replace_html 'results', :partial => 'results'
          end
        end
      end
    end
  end
  
  def opensearch
    respond_to do |format|
      format.xml { render :layout => false }
    end
  end

end
