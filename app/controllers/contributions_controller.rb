class ContributionsController < ApplicationController
  before_filter :only_admins
  before_filter :ensure_api_connection

  def index
    Donortools::Persona.setup_connection
    if params[:person_id]
      @person = Person.find(params[:person_id])
      if @donor = @person.donor
        @donations = Donortools::Donation.all(:persona_id => @donor.id).sort_by(&:received_date).reverse
      else
        @donations = []
      end
      render :action => 'person_index'
    else
      @donations = Donortools::Donation.all({}, :include => :person).sort_by(&:received_date).reverse
      @count_unsynced = Person.unsynced_to_donortools.count
    end
  end

  def sync
    if params[:person_id]
      if request.post?
        @person = Person.find(params[:person_id])
        @person.update_donor
        flash[:notice] = I18n.t('contributions.record_synced')
        redirect_to person_contributions_path(@person)
      end
    else
      if request.get?
        @unsynced_people = Person.unsynced_to_donortools(:all, :include => :family, :order => 'last_name, first_name').paginate(:page => params[:page], :per_page => 500)
      elsif request.post?
        if params[:all_ids] == 'true'
          @ids = Person.unsynced_to_donortools(:select => 'id').map { |p| p.id }
        else
          @ids = params[:ids].to_a
        end
        Person.all(:conditions => ["id in (?)", @ids.shift(Donortools::Persona::SYNC_AT_A_TIME)]).each do |person|
          person.update_donor
        end
        respond_to do |format|
          format.js
        end
      end
    end
  end

  private

    def only_admins
      unless @logged_in.admin?(:manage_contributions)
        render :text => I18n.t('only_admins'), :layout => true, :status => 401
        return false
      end
    end

    def ensure_api_connection
      unless Donortools::Persona.can_sync?
        render :text => I18n.t('contributions.api_not_configured', :url => administration_settings_path(:anchor => 'Services')), :layout => true
        return false
      end
    end

end
