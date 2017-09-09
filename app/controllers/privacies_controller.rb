class PrivaciesController < ApplicationController
  before_action :get_person

  def edit
    @children = @family.people.undeleted.children
    unless @logged_in.can_update?(@family)
      render html: t('not_authorized'), layout: true, status: 401
      return
    end
    flash[:warning] = t('privacies.family_hidden') unless @family.visible?
  end

  def update
    if params[:agree] || params[:agree_commit]
      update_consent
    else
      update_privacy
    end
  end

  def update_consent
    consent = ParentalConsent.new(@person, @logged_in, params[:agree])
    if consent.perform
      flash[:notice] = t('privacies.agreement_saved')
    else
      flash[:warning] = consent.errors.values.join('; ')
    end
    redirect_to edit_person_privacy_path(@person)
  end

  def update_privacy
    if @logged_in.can_update?(@family)
      @family.update_attributes!(family_params)
      updates = params[:memberships].try(:to_unsafe_h) # handled manually by MembershipSharingUpdater
      MembershipSharingUpdater.new(@logged_in, updates).perform
      if @family.visible?
        flash[:notice] = t('privacies.saved')
      else
        flash[:warning] = t('privacies.family_hidden')
      end
      redirect_to @person
    else
      render html: t('not_authorized'), layout: true, status: 401
    end
  end

  private

  def family_params
    if params[:agree_commit]
      params.permit(:agree, :commit)
    else
      params.require(:family).permit(
        :visible,
        people_attributes: %i(id visible share_address share_mobile_phone share_home_phone share_work_phone share_fax share_email share_birthday share_anniversary share_activity)
      )
    end
  end

  def get_person
    @person = Person.undeleted.find(params[:person_id])
    @family = @person.family
  end
end
