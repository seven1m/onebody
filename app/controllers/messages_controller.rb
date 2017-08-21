class MessagesController < ApplicationController
  load_and_authorize_parent :group, only: %i(index new create), optional: true
  load_and_authorize_resource except: %i(index new)

  def index
    if @logged_in.member_of?(@group) && @group.email?
      @messages = messages.order(created_at: :desc).page(params[:page])
    else
      render plain: t('not_authorized'), layout: true, status: 401
    end
  end

  def new
    if @group
      @message = @group.messages.new
    elsif params[:to_person_id] && (@person = Person.find(params[:to_person_id]))
      @message = Message.new(to_person_id: @person.id, subject: params[:subject])
    elsif params[:parent_id] && (@parent = Message.find(params[:parent_id]))
      @message = Message.new(parent: @parent, group_id: @parent.group_id, subject: "Re: #{@parent.subject}")
    end
    Authority.enforce(:create, @message, current_user)
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
  end

  def destroy
    @message.destroy
    redirect_to @message.group ? @message.group : stream_path
  end

  private

  def message_params
    params.require(:message).permit(:group_id, :to_person_id, :parent_id, :subject, :body, member_ids: [])
  end

  def create_private_message
    @person = Person.find(params[:message][:to_person_id])
    if @person.email && @logged_in.can_read?(@person)
      if send_message
        render plain: t('messages.sent'), layout: true unless @preview
      end
    else
      render plain: t('messages.no_email_for_person', name: @person.name), layout: true, status: 500
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
      render plain: t('not_authorized'), layout: true, status: 500
    end
  end

  def send_message
    attributes = message_params.merge(person: @logged_in)
    if attributes[:parent_id].present? && !@logged_in.can_read?(Message.find(attributes[:parent_id]))
      render plain: 'unauthorized', status: :unauthorized
      return
    end
    if params[:preview]
      @preview = Message.preview(attributes)
    else
      @message = Message.create_with_attachments(attributes, params[:files].to_a)
      if @message.errors.any?
        if @message.errors[:base] && @message.errors[:base].include?('already saved')
          @message.errors[:base].delete('already saved')
        end
        render action: 'new'
        false
      else
        true
      end
    end
  end
end
