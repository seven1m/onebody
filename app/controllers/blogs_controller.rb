class BlogsController < ApplicationController
  
  def show
    @person = Person.find(params[:person_id])
    if @logged_in.can_see? @person
      @blog_items = @person.blog_items.all(:limit => 25, :order => 'created_at desc')
      respond_to do |format|
        format.html
        format.js { render :partial => 'blog' }
      end
    else
      render :text => 'Blog not found.', :status => 404
    end
  end
  
  private
  
    def feature_enabled?
      unless Setting.get(:features, :blog)
        redirect_to people_path
        false
      end
    end
  
end
