class NotesController < ApplicationController

  load_and_authorize_parent :group, :person, shallow: true
  load_and_authorize_resource

  def index
    @notes = notes.order('created_at desc').page(params[:page])
  end

  def show
    @person = @note.person
  end

  def new
    @note = notes.new
  end

  def create
    @note = notes.new(note_params)
    @note.person = @logged_in
    # FIXME
    #if @note.group
      #raise 'error' unless @note.group.blog? and @note.group.can_post?(@logged_in)
    #end
    if @note.save
      flash[:notice] = t('notes.saved')
      redirect_to @note
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    if @note.update_attributes(note_params)
      redirect_to @note
    else
      render action: 'edit'
    end
  end

  def destroy
    @note.destroy
    redirect_to [@note.group || @note.person, :notes]
  end

  private

  def note_params
    params.require(:note).permit(:title, :body)
  end

end
