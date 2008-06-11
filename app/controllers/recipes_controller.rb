class RecipesController < ApplicationController
  def index
    @recipe_pages, @recipes = paginate :recipes, :per_page => 10, :order => 'title'
    biggest = Tag.find_by_sql("select count(tag_id) as num from recipes_tags where recipe_id is not null group by tag_id order by count(tag_id) desc limit 1").first.num.to_i rescue 0
    # to get a range of point sizes between 8pt and 16pt,
    # figure a factor to multiply by the count
    # 1..11 + 9 (10..20)
    @factor = biggest / 11
    @factor = 1 if @factor.zero?
    @tags = Tag.find :all, :conditions => '(select count(*) from recipes_tags where tag_id = tags.id and recipe_id is not null) > 0', :order => 'name'
  end

  def view
    @recipe = Recipe.find(params[:id])
  end

  def showmine
    @recipes = Recipe.find(:all, :conditions => ["person_id = (?)", @session['person'].id.to_s] )
    if @recipes == []
      flash[:notice]= "You don't have any recipes yet.  Why don't you add some?"
    end
  end
 
  def search
    if !params['criteria'] or 0 == params['criteria'].length
      @items = nil
    else
      recipes = Recipe.find(:all, :order => 'title',
        :conditions => [ "LOWER(#{sql_concat 'title', 'description', 'ingredients'}) LIKE ?",
        '%' + params['criteria'].downcase + '%' ])
      @item_pages, @items = paginate :recipes, :per_page => 5, :order => 'title',:conditions => [ "LOWER(#{sql_concat 'title', 'description', 'ingredients'}) LIKE ?",
        '%' + params['criteria'].downcase + '%' ]
      @mark_term = params['criteria']
    end    
  end


  def edit
    if params[:id]
      @recipe = Recipe.find params[:id]
    else
      @recipe = Recipe.new :person => @logged_in
    end
    if params[:event]
      @event = Event.find(params[:event])
      @recipe.event = @event
    else
      @event = @recipe.event
    end
    unless @recipe.admin?(@logged_in)
      raise 'You are not authorized to edit this recipe.'
    end
    if request.post?
      if @recipe.update_attributes params[:recipe]
        flash[:notice] = 'Recipe saved.'
        if params[:photo_url] and params[:photo_url].length > 7
          @recipe.photo = params[:photo_url]
        elsif params[:photo] and params[:photo].size > 0
          @recipe.photo = params[:photo]
        elsif params[:photo] and params[:photo] == 'remove'
          @recipe.photo = nil
        end
        @recipe.tags.destroy_all
        @recipe.tag_string = params[:tag_string]
        redirect_to @recipe
      else
        flash[:notice] = @recipe.errors.full_messages.join('; ')
      end
    end
  end

  def remove
    @recipe = Recipe.find params[:id]
    @recipe.event = nil
    @recipe.save
    redirect_to params[:return_to] or recipes_path
  end

  def delete
    @recipe = Recipe.find params[:id]
    @recipe.destroy if @recipe.admin? @logged_in
    flash[:notice] = 'Recipe deleted.'
    redirect_to params[:return_to] or recipes_path
  end
  
  def add_tags
    @recipe = Recipe.find params[:id]
    @recipe.tag_string = params[:tag_string]
    redirect_to @recipe
  end
  
  def delete_tag
    @recipe = Recipe.find params[:id]
    @recipe.tags.delete Tag.find(params[:tag_id])
    redirect_to @recipe
  end
  
  def photo
    @recipe = Recipe.find params[:id].to_i
    send_photo @recipe
  end

end
