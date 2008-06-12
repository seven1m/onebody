class MessagesController < ApplicationController
  
  def new
    if params[:to_person_id] and @person = Person.find(params[:to_person_id])
      @message = Message.new(:to_person_id => @person.id)
    elsif params[:group_id] and @group = Group.find(params[:group_id])
      @message = Message.new(:group_id => @group.id)
    elsif params[:parent_id] and @parent = Message.find(params[:parent_id]) and @logged_in.can_see?(@parent)
      @message = Message.new(:parent => @parent, :group_id => @parent.group_id, :subject => "Re: #{@parent.subject}", :dont_send => true)
    else
      raise 'Unknown message type.'
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
    if @person.email
      attributes = params[:message].merge(:person => @logged_in, :to => @person)
      if params[:preview]
        @msg = @message = Message.new(attributes) # TODO: get rid of this @msg at some point
        preview = render_to_string(:file => File.join(RAILS_ROOT, 'app/views/notifier/message.html.erb'), :layout => false)
        preview.gsub!(/\n/, "<br/>\n").gsub!(/http:\/\/[^\s<]+/, '<a href="\0">\0</a>')
        render(:update) do |page|
          page.replace_html 'preview-email', preview
          page.show 'preview'
        end
      else
        @message = Message.create(attributes)
        if @message.errors.any?
          add_errors_to_flash(@message)
          redirect_back
        else
          render :text => 'Your message has been sent.', :layout => true
        end
      end
    else
      render :text => "Sorry. We don't have an email address on file for #{@person.name}.", :layout => true, :status => :error
    end
  end
  
  def create_group_message
    @group = Group.find(params[:message][:group_id])
    if @group.can_post? @logged_in
      @message = Message.create params[:message].merge(:person => @logged_in, :group => @group, :dont_send => true)
      if @message.errors.any?
        add_errors_to_flash(@message)
        redirect_back
      else
        if params[:file] and params[:file].size > 0
          attachment = @message.attachments.create(
            :name => File.split(params[:file].original_filename).last,
            :content_type => params[:file].content_type
          )
          if attachment.errors.any?
            add_errors_to_flash(attachment)
            redirect_back
          else
            attachment.file = params[:file]  
          end
        end
        @message.send_to_group
        render :text => 'Your message has been sent.', :layout => true
      end
    else
      render :text => 'You are not authorized to post to this group.', :layout => true, :status => :error
    end
  end
  
  public
  
  def destroy
    @message = Message.find(params[:id])
    if @logged_in.can_edit? @message
      @message.destroy
      redirect_back
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
      redirect_back
    else
      render :text => 'You are not authorized to delete this message.', :status => 500
    end
  end

  def preview_message
    params[:subject] = params[:message] ? params[:message][:subject] : params[:subject]
    params[:body] = params[:message] ? params[:message][:body] : params[:body]
    if params[:subject].to_s.any? or params[:body].to_s.any?
      if params[:id]
        @person = Person.find params[:id]
      else
        @group = Group.find params[:group_id]
      end
      @msg = Message.new :person => @logged_in, :subject => params[:subject], :body => params[:body], :share_email => false, :created_at => Time.now
      if @person
        @to = @msg.to = @person
        @msg.share_email = params[:share_email]
      else
        @msg.group = @group
        @to = Person.new
      end
      respond_to do |wants|
        wants.html { render :file => File.join(RAILS_ROOT, 'app/views/notifier/message.html.erb'), :layout => false }
        wants.js do
          preview = render_to_string :file => File.join(RAILS_ROOT, 'app/views/notifier/message.html.erb'), :layout => false
          preview.gsub!(/\n/, "<br/>\n").gsub!(/http:\/\/[^\s<]+/, '<a href="\0">\0</a>')
          render(:update) do |page|
            page.replace_html 'preview-email', preview
            page.show 'preview'
          end
        end
      end
    else
      render :nothing => true
    end
  end
  
  def view_attachment
    attachment = Attachment.find params[:id]
    unless attachment.message and attachment.message.group and @logged_in.sees? attachment.message.group
      render :text => 'You are not authorized to view this attachment.', :layout => true
      return
    end
    # TODO: routes this file serve through regular web server
    send_data File.read(attachment.file_path), :filename => attachment.name, :type => attachment.content_type, :disposition => 'inline'
  end
end
