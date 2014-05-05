class MessagesController < ApplicationController

  def index
    @group = Group.find(params[:group_id])
    if @logged_in.can_see?(@group) and @group.email?
      @messages = @group.messages.order('created_at desc').page(params[:page])
    else
      render text: t('groups.not_authorized_view'), layout: true, status: 401
    end
  end

  def new
    if params[:to_person_id] and @person = Person.find(params[:to_person_id]) and @logged_in.can_see?(@person)
      @message = Message.new(to_person_id: @person.id)
    elsif params[:group_id] and @group = Group.find(params[:group_id]) and @group.can_post?(@logged_in)
      @message = Message.new(group_id: @group.id)
      if params[:message]
        @message.subject = params[:message][:subject]
        @message.body    = params[:message][:body]
      end
    elsif params[:parent_id] and @parent = Message.find(params[:parent_id]) and @logged_in.can_see?(@parent)
      @message = Message.new(parent: @parent, group_id: @parent.group_id, subject: "Re: #{@parent.subject}", dont_send: true)
    else
      render text: t('There_was_an_error'), layout: true, status: 500
    end
  end

  def create
    if m = params[:message]
      if m[:to_person_id].to_i > 0
        create_private_message
      elsif m[:group_id].to_i > 0
        create_group_message
      else
        raise t('messages.unknown_type')
      end
    else
      raise t('messages.missing_param')
    end
  end

  def show
    @message = Message.find(params[:id])
    unless @logged_in.can_see?(@message)
      render text: t('messages.not_found'), layout: true, status: 404
    end
  end

  def destroy
    @message = Message.find(params[:id])
    if @logged_in.can_edit?(@message)
      @message.destroy
      redirect_to @message.group ? @message.group : stream_path
    else
      render text: t('messages.not_authorized_delete'), layout: true, status: 500
    end
  end

  private

  def message_params
    params.require(:message).permit(:group_id, :to_person_id, :parent_id, :subject, :body)
  end

  def create_private_message
    @person = Person.find(params[:message][:to_person_id])
    if @person.email and @logged_in.can_see?(@person)
      if send_message
        unless @preview
          render text: t('messages.sent'), layout: true
        end
      end
    else
      render text: t('messages.no_email_for_person', name: @person.name), layout: true, status: 500
    end
  end

  def create_group_message
    @group = Group.find(params[:message][:group_id])
    if @group.can_post? @logged_in
      if send_message
        unless @preview
          flash[:notice] = t('messages.sent')
          redirect_to @group
        end
      end
    else
      render text: t('groups.not_authorized_post'), layout: true, status: 500
    end
  end

  def send_message
    attributes = message_params.merge(person: @logged_in)
    if attributes[:parent_id] and not @logged_in.can_see?(Message.find(attributes[:parent_id]))
      render text: 'unauthorized', status: :unauthorized
      return
    end
    if params[:preview]
      @preview = Message.preview(attributes)
    else
      @message = Message.create_with_attachments(attributes, params[:files].to_a)
      if @message.errors.any?
        add_errors_to_flash(@message)
        redirect_back
        false
      else
        true
      end
    end
  end
end
