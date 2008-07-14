class BlogsController < ApplicationController
  
  def show
    @person = Person.find(params[:person_id])
    if @logged_in.can_see? @person
      @objects = @person.blog_items
      @pictures = @objects.select { |o| o.is_a? Picture }
      @non_pictures = @objects.select { |o| !o.is_a? Picture }
      respond_to do |format|
        format.html
        format.js { render :partial => 'blog' }
      end
    else
      render :text => 'Blog not found.', :status => 404
    end
  end
  
end
