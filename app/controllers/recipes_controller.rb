
class RecipesController < ApplicationController


 def index
 end

  def list
    @recipe_pages, @recipes = paginate :recipes, :per_page => 10, :order => 'title'
  end

 def show
    @recipe = Recipe.find(params[:id])
 end

 def showmine
   @recipes = Recipe.find(:all, :conditions => ["person_id = (?)", @session['person'].id.to_s] )
   if @recipes == []
      flash[:notice]= "You don't have any recipes yet.  Why don't you add some?"
   end
 end
 
 def search
     if 0 == @params['criteria'].length
      @items = nil
    else
      @items = Recipe.find(:all, :order => 'title',
        :conditions => [ 'LOWER(concat(title,description,ingredients)) LIKE ?',
        '%' + @params['criteria'].downcase + '%' ])
      @mark_term = @params['criteria']
    end
    render_without_layout
 end


  def edit
    if params[:id]
      @recipe = Recipe.find params[:id]
    else
      @recipe = Recipe.new :person => @logged_in
    end
    unless @recipe.admin?(@logged_in)
      raise 'You are not authorized to edit this recipe.'
    end
    if request.post?
      if @recipe.update_attributes params[:recipe]
        flash[:notice] = 'Recipe saved.'
        redirect_to :action => 'show', :id => @recipe
      else
        flash[:notice] = @recipe.errors.full_messages.join('; ')
      end
    end
  end

 
  def delete
    @recipe = Recipe.find params[:id]
    @recipe.destroy if @recipe.admin? @logged_in
    flash[:notice] = 'Recipe deleted.'
    redirect_to :action => 'index'
  end
 
 def add_tags
    @recipe = Recipe.find params[:id]
    @recipe.tag_string = params[:tag_string]
    redirect_to :action => 'show', :id => @recipe
 end
  
 def delete_tag
    @recipe = Recipe.find params[:id]
    @recipe.tags.delete Tag.find(params[:tag_id])
    redirect_to :action => 'show', :id => @recipe
 end

end
