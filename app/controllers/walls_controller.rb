class WallsController < ApplicationController
  
  def show
    @person = Person.find(params[:person_id])
    if @logged_in.can_see?(@person) and @person.wall_enabled?
      respond_to do |wants|
        wants.html do
          @messages = @person.wall_messages.paginate(:all, :page => params[:page])
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
  
  # /people/1/wall/with?id=2
  # show 2 walls (wall-to-wall)
  def with
    @person1 = Person.find(params[:person_id])
    @person2 = Person.find(params[:id])
    if @person1 and @person2
      if @logged_in.can_see?(@person1, @person2) and @person1.wall_enabled? and @person2.wall_enabled?
        @messages = Message.find(:all, :conditions => ['(wall_id = ? and person_id = ?) or (wall_id = ? and person_id = ?)', @person1.id, @person2.id, @person2.id, @person1.id], :order => 'created_at desc')
      else
        render :text => 'One or more walls not found.', :status => 404
      end
    else
      render :text => 'Must specify exactly two people', :status => 500
    end
  end
end
