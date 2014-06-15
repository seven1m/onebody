class NotesController < ApplicationController

  load_and_authorize_parent :person, shallow: true
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
