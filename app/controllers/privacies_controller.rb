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
        all = %w(address home_phone mobile_phone work_phone fax email birthday anniversary)
        @visible_to_everyone = all.select { |a| @person.send("share_#{a}?") }
        @sharable_with_group = all - @visible_to_everyone
        render :action => 'edit_membership'
      else
        render :text => t('not_authorized'), :layout => true, :status => 401
      end
    elsif @person = Person.find(params[:person_id])
      if @logged_in.can_edit?(@person)
        @family = @person.family
        unless @family.visible?
          flash[:warning] = t('privacies.family_hidden', :your => @family == @logged_in.family ? t('your') : t('privacies.this'))
        end
      else
        render :text => t('not_authorized'), :layout => true, :status => 401
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
    elsif params[:agree] or params[:commit] == t('privacies.i_agree')
      update_consent
    else
      render :text => t('privacies.missing_params'), :status => 500
    end
  end

  private

  def update_membership
    @group = Group.find(params[:group_id])
    @membership = Membership.find(params[:membership_id])
    if @logged_in.can_edit?(@membership)
      sharing = params[:membership].reject { |k, v| k.to_s !~ /^share_/ }
      if @membership.update_attributes(sharing)
        flash[:notice] = t('privacies.saved')
        redirect_to edit_group_membership_privacy_path(@group, @membership)
      else
        edit; render :action => 'edit'
      end
    else
      render :text => t('not_authorized'), :layout => true, :status => 401
    end
  end

  def update_person
    @person = Person.find(params[:person_id])
    @family = @person.family
    if @logged_in.can_edit?(@family)
      if person = @family.people.find(params[:person_id])
        sharing = params[:person].reject { |k, v| k.to_s !~ /^wall_enabled$|^messages_enabled$|^visible$|^share_/ }
        sharing.each { |k, v| sharing[k] = (v == 'nil') ? nil : v }
        if person.update_attributes(sharing)
          if person.visible?
            flash[:notice] = t('privacies.saved_personal', :name => person.name)
          else
            flash[:warning] = t('privacies.person_is_hidden', :name => person.name)
          end
        else
          add_errors_to_flash(person)
        end
      end
      redirect_to edit_person_privacy_path(@person, :section => params[:anchor])
    else
      render :text => t('not_authorized'), :layout => true, :status => 401
    end
  end

  def update_family
    @person = Person.find(params[:person_id])
    @family = @person.family
    if @logged_in.can_edit?(@family)
      sharing = params[:family].reject { |k, v| k.to_s !~ /^wall_enabled$|^visible$|^share_/ }
      @family.update_attributes(sharing)
      if @family.visible?
        flash[:notice] = t('privacies.saved_family')
        flash[:warning] = nil
      else
        flash[:warning] = t('privacies.family_hidden', :your => @family == @logged_in.family ? t('your') : t('privacies.this'))
      end
      redirect_to edit_person_privacy_path(@person, :section => params[:anchor])
    else
      render :text => t('not_authorized'), :layout => true, :status => 401
    end
  end

  def update_consent
    @person = Person.find(params[:person_id])
    @family = @person.family
    if @logged_in.can_edit?(@family) and @family == @logged_in.family
      if params[:agree] == t('privacies.i_agree') + "."
        if person = @family.people.find(params[:person_id])
          @person.parental_consent = "#{@logged_in.name} (#{@logged_in.id}) at #{Time.now.to_s}"
          @person.save
          flash[:notice] = t('privacies.agreement_saved')
        end
      elsif params[:commit] == t('privacies.i_agree')
        flash[:warning] = t('privacies.you_must_check_agreement_statement')
      end
      redirect_to edit_person_privacy_path(@person, :section => params[:anchor])
    else
      render :text => t('not_authorized'), :layout => true, :status => 401
    end
  end

end
