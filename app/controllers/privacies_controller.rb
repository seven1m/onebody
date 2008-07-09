class PrivaciesController < ApplicationController

  def show
    id = params[:person_id] || @logged_in.id
    redirect_to edit_person_privacy_path(id, params_without_action.merge(:anchor => "p#{id}"))
  end

  def edit
    if @person = Person.find(params[:person_id]) and @logged_in.can_edit?(@person)
      @family = @person.family
      
      unless @family.visible?
        flash[:warning] = "#{@family == @logged_in.family ? 'Your' : 'This'} family is currently hidden from all pages on this site!"
      end
    else
      render :text => 'You are not authorized to edit this person.', :status => 401
    end
  end
  
  def update
    @person = Person.find(params[:person_id])
    @family = @person.family
    if not @logged_in.can_edit? @family
      render :text => "You may not edit these settings. Sorry.", :status => 401
      return
    elsif params[:person]
      if person = @family.people.find(params[:person_id])
        params[:person].each { |k, v| params[:person][k] = (v == 'nil') ? nil : v } 
        if person.update_attributes params[:person]
          if person.visible?
            flash[:notice] = "Personal settings saved for #{person.name}."
          else
            flash[:warning] = "#{person.name} has been hidden from all pages on this site!"
          end
        else
          flash[:notice] = person.errors.full_messages.join('; ')
        end
      end
    elsif params[:family]
      @family.update_attributes params[:family]
      if @family.visible?
        flash[:notice] = "Family settings saved."
        flash[:warning] = nil
      else
        flash[:warning] = "#{@family == @logged_in.family ? 'Your' : 'This'} family has been hidden from all pages on this site!"
      end
    elsif params[:agree] == 'I Agree.'
      if person = @family.people.find(params[:person_id])
        @person.parental_consent = "#{@logged_in.name} (#{@logged_in.id}) at #{Time.now.to_s}"
        @person.save
        flash[:notice] = 'Agreement saved.'
      end
    elsif params[:commit] == 'I Agree'
      flash[:warning] = 'You must check the box indicating you agree to the statement below.'
    end
    redirect_to edit_person_privacy_path(@person, :section => params[:anchor])
  end

end
