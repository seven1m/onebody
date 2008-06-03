class WallsController < ApplicationController
  
  # show more than 1 wall (wall-to-wall)
  # requires an id[] array of two people ids in params
  def index
    if params[:id].is_a?(Array) and params[:id].length == 2
      @person1, @person2 = Person.find(:all, :conditions => ['id in (?)', params[:id]])
      if @logged_in.can_see?(@person1, @person2) and @person1.wall_enabled? and @person2.wall_enabled?
        @messages = Message.find(:all, :conditions => ['(wall_id = ? and person_id = ?) or (wall_id = ? and person_id = ?)', @person1.id, @person2.id, @person2.id, @person1.id], :order => 'created_at desc')
      else
        render :text => 'One or more walls not found.', :status => 404
      end
    else
      render :text => 'Must specify exactly two people', :status => 500
    end
  end

  # show 1 wall
  def show
    @person = params[:id] ? Person.find(params[:id]) : @logged_in
    if @logged_in.can_see?(@person) and @person.wall_enabled?
      respond_to do |wants|
        wants.html do
          @messages = @person.wall_messages.find(:all)
        end
        wants.js do
          @messages = @person.wall_messages.find(:all, :limit => 10)
          render :partial => 'wall'
        end
      end
    else
      render :text => 'Wall not found.', :status => 404
    end
  end
end
