class MessagesController < ApplicationController

  def index
    @group = Group.find(params[:group_id])
    if @logged_in.can_see?(@group) and @group.email?
      @messages = @group.messages.paginate(:order => 'created_at desc', :page => params[:page])
    else
      render :text => 'You are not authorized to view this group', :layout => true, :status => 401
    end
  end
  
  def new
    if params[:to_person_id] and @person = Person.find(params[:to_person_id]) and @logged_in.can_see?(@person)
      @message = Message.new(:to_person_id => @person.id)
    elsif params[:group_id] and @group = Group.find(params[:group_id]) and @group.can_post?(@logged_in)
      @message = Message.new(:group_id => @group.id)
    elsif params[:parent_id] and @parent = Message.find(params[:parent_id]) and @logged_in.can_see?(@parent)
      @message = Message.new(:parent => @parent, :group_id => @parent.group_id, :subject => "Re: #{@parent.subject}", :dont_send => true)
    else
      render :text => 'There was an error in your request.', :layout => true, :status => 500
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
    if params[:note_private] == 'true'
      @message = Message.new(
        :person_id    => @logged_in.id,
        :to_person_id => @person.id,
        :body         => params[:message][:body]
      )
      render :action => 'new'
      return
    end
    if @logged_in.can_see?(@person) and @person.wall_enabled?
      message = @person.wall_messages.create(params[:message].merge(:subject => 'Wall Post', :person => @logged_in))
      respond_to do |format|
        format.html do
          if message.errors.any?
            flash[:wall_notice] = "There was an error posting the wall message: #{message.errors.full_messages.join('; ')}"
          end
          redirect_to person_path(@person) + '#wall'
        end
        format.js do
          if message.errors.any?
            @wall_notice = "There was an error posting the wall message: #{message.errors.full_messages.join('; ')}"
          end
          @messages = @person.wall_messages.find(:all, :limit => 10)
          render :partial => 'walls/wall'
        end
      end
    else
      render :text => 'Wall not found.', :layout => true, :status => 404
    end
  end
  
  def create_private_message
    @person = Person.find(params[:message][:to_person_id])
    if @person.email and @logged_in.can_see?(@person)
      if send_message
        unless @preview
          render :text => 'Your message has been sent.', :layout => true
        end
      end
    else
      render :text => "Sorry. We don't have an email address on file for #{@person.name}.", :layout => true, :status => 500
    end
  end
  
  def create_group_message
    @group = Group.find(params[:message][:group_id])
    if @group.can_post? @logged_in
      if send_message
        unless @preview
          flash[:notice] = 'Your message has been sent.'
          redirect_to @group
        end
      end
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
        redirect_back
        false
      else
        true
      end
    end
  end
  
  public
  
  def show
    @message = Message.find(params[:id])
    unless @logged_in.can_see?(@message)
      render :text => 'Message not found.', :layout => true, :status => 404
    end
  end
  
  def destroy
    @message = Message.find(params[:id])
    if @logged_in.can_edit?(@message)
      @message.destroy
      redirect_to @message.group ? @message.group : stream_path
    else
      render :text => 'You are not authorized to delete this message.', :layout => true, :status => 500
    end
  end
end
