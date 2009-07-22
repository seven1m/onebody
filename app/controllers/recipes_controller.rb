class RecipesController < ApplicationController

  def index
    if params[:person_id]
      @person = Person.find(params[:person_id])
      if @logged_in.can_see?(@person)
        @recipes = @person.recipes.paginate(:order => 'created_at desc', :page => params[:page])
      else
        render :text => 'You are not authorized to view this person', :layout => true, :status => 401
      end
      @tags = Recipe.tag_counts(:conditions => ['recipes.id in (?)', @recipes.map { |v| v.id } || [0]])
    else
      @recipes = Recipe.paginate(:order => 'title', :page => params[:page])
      @tags = Recipe.tag_counts
    end
  end

  def show
    @recipe = Recipe.find(params[:id])
  end

  def new
    @recipe = Recipe.new(:person => @logged_in)
  end
  
  def create
    @recipe = Recipe.new(:person => @logged_in)
    if @recipe.update_attributes(params[:recipe])
      flash[:notice] = 'Recipe saved.'
      redirect_to @recipe
    else
      render :action => 'new'
    end
  end
  
  def edit
    @recipe = Recipe.find(params[:id])
    unless @logged_in.can_edit?(@recipe)
      render :text => 'You are not authorized to edit this recipe.', :layout => true, :status => 401
    end
  end
  
  def update
    @recipe = Recipe.find(params[:id])
    @recipe.tag_list.remove(params[:remove_tag]) if params[:remove_tag]
    @recipe.tag_list.add(*params[:add_tags].split) if params[:add_tags]
    @recipe.save if params[:remove_tag] or params[:add_tags]
    if @logged_in.can_edit?(@recipe)
      if @recipe.update_attributes(params[:recipe])
        flash[:notice] = 'Recipe saved.'
        redirect_to @recipe
      else
        render :action => 'edit'
      end
    else
      render :text => 'You are not authorized to edit this recipe.', :layout => true, :status => 401
    end
  end

  def destroy
    @recipe = Recipe.find(params[:id])
    if @logged_in.can_edit?(@recipe)
      @recipe.destroy
      flash[:notice] = 'Recipe deleted.'
      redirect_to recipes_path
    else
      render :text => 'You are not authorized to delete this recipe.', :layout => true, :status => 401
    end
  end

end
