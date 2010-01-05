class NotesController < ApplicationController

  def index
    if params[:person_id]
      @person = Person.find(params[:person_id])
      if @logged_in.can_see?(@person)
        @notes = @person.notes.paginate(:order => 'created_at desc', :page => params[:page])
      else
        render :text => I18n.t('not_authorized'), :layout => true, :status => 401
      end
    elsif params[:group_id]
      @group = Group.find(params[:group_id])
      if @logged_in.can_see?(@group) and @group.blog?
        @notes = @group.notes.paginate(:order => 'created_at desc', :page => params[:page])
      else
        render :text => I18n.t('not_authorized'), :layout => true, :status => 401
      end
    else
      render :text => 'Error.', :status => 400
    end
  end

  def show
    @note = Note.find(params[:id])
    if @logged_in.can_see?(@note)
      @person = @note.person
    else
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
  def new
    @note = Note.new(:group => Group.find_by_id(params[:group_id]))
  end
  
  def create
    @note = Note.new(params[:note])
    @note.group_id = params[:note][:group_id] if params[:note][:group_id]
    if @note.group
      raise 'error' unless @note.group.blog? and @note.group.can_post?(@logged_in)
    end
    @note.person = @logged_in
    if @note.save
      flash[:notice] = 'Note saved.'
      redirect_to params[:redirect_to] || @note
    else
      render :action => 'new'
    end
  end
  
  def edit
    @note = Note.find(params[:id])
    unless @logged_in.can_edit?(@note)
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
  def update
    @note = Note.find(params[:id])
    if @logged_in.can_edit?(@note)
      if @note.update_attributes(params[:note])
        redirect_to @note
      else
        render :action => 'edit'
      end
    else
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
  def destroy
    @note = Note.find(params[:id])
    if @logged_in.can_edit?(@note)
      @note.destroy
      if @note.group
        redirect_to group_path(@note.group, :anchor => 'blog')
      else
        redirect_to person_path(@note.person, :anchor => 'blog')
      end
    else
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
end
