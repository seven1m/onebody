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
    if @note.person == @logged_in or @logged_in.admin?(:manage_notes)
      unless params[:group_id] and @group = Group.find_by_id(params[:group_id]) and @group.can_post?(@logged_in)
        @group = nil
      end
      if request.post?
        @note.update_attributes params[:note]
        if @note.group
          redirect_to group_url(:id => @note.group, :anchor => 'blog')
        else
          redirect_to person_url(:id => @note.person, :anchor => 'blog')
        end
      end
    else
      render :text => 'You are not authorized.', :layout => true
    end
  end
  
  def delete
    note = Note.find params[:id]
    if note.person == @logged_in or @logged_in.admin?(:manage_notes)
      note.update_attribute :deleted, true
    end
    redirect_to person_url(:id => note.person, :anchor => 'notes')
  end
end
