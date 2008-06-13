class MessagesController < ApplicationController
  
  def new
    if params[:to_person_id] and @person = Person.find(params[:to_person_id]) and @logged_in.can_see?(@person)
      @message = Message.new(:to_person_id => @person.id)
    elsif params[:group_id] and @group = Group.find(params[:group_id]) and @group.can_post?(@logged_in)
      @message = Message.new(:group_id => @group.id)
    elsif params[:parent_id] and @parent = Message.find(params[:parent_id]) and @logged_in.can_see?(@parent)
      @message = Message.new(:parent => @parent, :group_id => @parent.group_id, :subject => "Re: #{@parent.subject}", :dont_send => true)
    else
      render :text => 'There was an error in your request.', :status => 500
    end
  end
  
  def create
    if m = params[:message]
      if m[:wall_id].to_i > 0
        create_wall_message
      elsif m[:to_person_id].to_i > 0
        create_private_message
      elsif m[:group_id].to_i > 0
        create_group_message
      else
        raise 'Unknown message type.'
      end
    else
      raise 'Missing the message param.'
    end
  end
  
  private
  
  def create_wall_message
    @person = Person.find(params[:message][:wall_id])
    if @logged_in.can_see?(@person) and @person.wall_enabled?
      @person.wall_messages.create! params[:message].merge(:subject => 'Wall Post', :person => @logged_in)
      respond_to do |format|
        format.html { redirect_to person_path(@person) + '#wall' }
        format.js do
          @messages = @person.wall_messages.find(:all, :limit => 10)
          render :partial => 'walls/wall'
        end
      end
    else
      render :text => 'Wall not found.', :status => 404
    end
  end
  
  def create_private_message
    @person = Person.find(params[:message][:to_person_id])
    if @person.email and @logged_in.can_see?(@person)
      send_message
    else
      render :text => "Sorry. We don't have an email address on file for #{@person.name}.", :layout => true, :status => 500
    end
  end
  
  def create_group_message
    @group = Group.find(params[:message][:group_id])
    if @group.can_post? @logged_in
      send_message
    else
      render :text => 'You are not authorized to post to this group.', :layout => true, :status => 500
    end
  end
  
  def send_message
    attributes = params[:message].merge(:person => @logged_in)
    if params[:preview]
      @preview = Message.preview(attributes)
    else
      @message = Message.create_with_attachments(attributes, [params[:file]].compact)
      if @message.errors.any?
        add_errors_to_flash(@message)
        return redirect_back
      else
        render :text => 'Your message has been sent.', :layout => true
      end
    end
  end
  
  public
  
  def destroy
    @message = Message.find(params[:id])
    if @logged_in.can_edit? @message
      @message.destroy
      return redirect_back
    else
      render :text => 'Not authorized.', :status => 500
    end
  end
  
  def show
    @message = Message.find(params[:id])
    unless @logged_in.sees? @message
      render :text => 'You are not allowed to view messages in this private group.'
    end
  end
  
  def destroy
    @message = Message.find(params[:id])
    if @logged_in.can_edit?(@message)
      @message.destroy
      return redirect_back
    else
      render :text => 'You are not authorized to delete this message.', :status => 500
    end
  end
end
