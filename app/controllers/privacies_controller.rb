class PrivaciesController < ApplicationController

  cache_sweeper :person_sweeper, :family_sweeper, :only => %w(update)

  def show
    if params[:find] == 'memberships'
      raise 'error' unless Membership.sharing_columns.include?(prop = "share_#{params[:sharing]}")
      @memberships = @logged_in.memberships.all(:conditions => ["#{prop} = ?", true])
    elsif params[:membership_id]
      redirect_to edit_group_membership_privacy_path(params[:group_id], params[:membership_id])
    else
      id = params[:person_id] || @logged_in.id
      redirect_to edit_person_privacy_path(id, params_without_action.merge(:anchor => "p#{id}"))
    end
  end
  
  def edit
    if params[:group_id]
      @group ||= Group.find(params[:group_id])
      @membership ||= Membership.find(params[:membership_id])
      @person = @membership.person
      if @person.member_of?(@group) and @logged_in.can_edit?(@person)
        render :action => 'edit_membership'
      else
        render :text => 'You are not authorized to edit this person.', :layout => true, :status => 401
      end
    elsif @person = Person.find(params[:person_id])
      if @logged_in.can_edit?(@person)
        @family = @person.family
        unless @family.visible?
          flash[:warning] = "#{@family == @logged_in.family ? 'Your' : 'This'} family is currently hidden from all pages on this site!"
        end
      else
        render :text => 'You are not authorized to edit this person.', :layout => true, :status => 401
      end
    end
  end
  
  def update
    if params[:membership]
      update_membership
    elsif params[:person]
      update_person
    elsif params[:family]
      update_family
    elsif params[:agree] or params[:commit] == 'I Agree'
      update_consent
    else
      render :text => 'missing params', :status => 500
    end
  end
  
  private
  
  def update_membership
    @group = Group.find(params[:group_id])
    @membership = Membership.find(params[:membership_id])
    if @membership.update_attributes(params[:membership])
      flash[:notice] = 'Settings saved.'
    else
      edit; render :action => 'edit'
    end
    redirect_to edit_group_membership_privacy_path(@group, @membership)
  end
  
  def update_person
    @person = Person.find(params[:person_id])
    @family = @person.family
    if @logged_in.can_edit?(@family)
      if person = @family.people.find(params[:person_id])
        params[:person].each { |k, v| params[:person][k] = (v == 'nil') ? nil : v } 
        if person.update_attributes(params[:person])
          if person.visible?
            flash[:notice] = "Personal settings saved for #{person.name}."
          else
            flash[:warning] = "#{person.name} has been hidden from all pages on this site!"
          end
        else
          add_errors_to_flash(person)
        end
      end
      redirect_to edit_person_privacy_path(@person, :section => params[:anchor])
    else
      render :text => "You may not edit these settings. Sorry.", :status => 401
    end
  end
    
  def update_family
    @person = Person.find(params[:person_id])
    @family = @person.family
    if not @logged_in.can_edit? @family
      render :text => "You may not edit these settings. Sorry.", :status => 401
      return
    else
      @family.update_attributes params[:family]
      if @family.visible?
        flash[:notice] = "Family settings saved."
        flash[:warning] = nil
      else
        flash[:warning] = "#{@family == @logged_in.family ? 'Your' : 'This'} family has been hidden from all pages on this site!"
      end
    end
    redirect_to edit_person_privacy_path(@person, :section => params[:anchor])
  end
  
  def update_consent
    @person = Person.find(params[:person_id])
    @family = @person.family
    if params[:agree] == 'I Agree.'
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
