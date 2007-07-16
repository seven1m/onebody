class NotesController < ApplicationController
  def view
    @note = Note.find params[:id]
    unless @logged_in.sees?(@note.person)
      render :text => 'You are not authorized to view this note', :layout => true
      return false
    end
    @person = @note.person
  end
  
  def edit
    @note = params[:id] ? Note.find(params[:id]) : Note.new(:person => @logged_in)
    if @note.person == @logged_in or @logged_in.admin?
      if request.post?
        @note.update_attributes params[:note]
        redirect_to :action => 'view', :id => @note
      end
    else
      render :text => 'You are not authorized.', :layout => true
    end
  end
  
  def delete
    note = Note.find params[:id]
    if note.person == @logged_in or @logged_in.admin?
      note.update_attribute :deleted, true
    end
    redirect_to person_url(:id => note.person), :anchor => 'notes'
  end
end
