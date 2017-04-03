class AccountsController < ApplicationController
  skip_before_filter :authenticate_user, except: %w(edit update)

  load_and_authorize_parent :person, permit: :edit, only: %w(edit update)

  def show
    if params[:person_id]
      redirect_to person_account_path(params[:person_id])
    else
      redirect_to new_account_path
    end
  end

  def new
    @verification ||= Verification.new
    if params[:forgot]
      render action: 'forgot'
    elsif params[:email]
      render action: 'new_by_email'
    elsif params[:phone]
      render action: 'new_by_mobile'
    elsif Setting.get(:features, :sign_up)
      @signup = Signup.new
      render action: 'new'
    else
      render action: 'new'
    end
  end

  def create
    if params[:signup]
      @signup = Signup.new(params[:signup])
      if @signup.save
        if @signup.approval_sent?
          render text: t('accounts.pending_approval'), layout: true
        elsif @signup.verification_sent?
          if @signup.found_existing?
            flash.now[:notice] = t('accounts.create.existing_account.by_email')
          end
          render text: t('accounts.verification_email_sent'), layout: true
        elsif @signup.can_verify_mobile?
          flash[:notice] = t('accounts.create.existing_account.by_mobile')
          redirect_to new_account_path(phone: @signup.mobile_phone)
        end
      else
        render action: 'new'
      end
    elsif params[:verification]
      @verification = Verification.new(verification_params)
      if @verification.save
        if params[:phone]
          flash[:notice] = t('accounts.verification_message_sent')
          render action: 'verify_code'
        elsif params[:via_admin]
          flash[:warning] = t('accounts.verification.email.via_admin')
          redirect_to @verification.people.first
        else
          render text: t('accounts.verification_email_sent'), layout: true
        end
      else
        new
      end
    else
      @signup = Signup.new
      flash[:warning] = t('accounts.fill_required_fields')
      render action: 'new'
    end
  end

  def verify_code
    @verification = Verification.find(params[:id])
    if not @verification.pending?
      render text: t('accounts.verification.not_pending', url: new_account_path(forgot: true)), layout: true
    elsif request.post?
      if @verification.check!(params[:code])
        redirect_for_verification
      else
        render text: t('accounts.wrong_code_html'), layout: true, status: :bad_request
      end
    end
  end

  def edit
  end

  def update
    if @person.update_attributes(person_params)
      flash[:notice] = t('Changes_saved')
      redirect_to @person
    else
      render action: 'edit'
    end
  end

  def select
    if session[:select_from_people]
      @people = session[:select_from_people]
      if request.post? and @person = @people.detect { |p| p.id == params[:id].to_i }
        session[:logged_in_id] = @person.id
        session[:select_from_people] = nil
        flash[:warning] = t('accounts.must_set_email_pass')
        redirect_to edit_person_account_path(@person)
      end
    else
      render text: t('Page_no_longer_valid'), layout: true, status: :gone
    end
  end

  private

  def redirect_for_verification
    if @verification.event
      (first_name, last_name) = @verification.name.split(/\s+/, 2)
      person = @verification.people.first || Person.create!(first_name: first_name, last_name: last_name)
      session[:registration_logged_in_id] = person.id
      redirect_to new_event_registration_path(@verification.event)
    elsif @verification.people.count > 1
      session[:select_from_people] = @verification.people.to_a
      redirect_to select_account_path
    else
      person = @verification.people.first
      session[:logged_in_id] = person.id
      flash[:warning] = if @verification.mobile_phone?
        t('accounts.set_your_email')
      else
        t('accounts.set_your_email_may_be_different')
      end
      redirect_to edit_person_account_path(person)
    end
  end

  def verification_params
    params.require(:verification).permit(:email, :mobile_phone, :carrier)
  end

  def person_params
    params.require(:person).permit(:email, :password, :password_confirmation)
  end

  def check_ssl
    unless request.ssl? or !Rails.env.production? or !Setting.get(:features, :ssl)
      redirect_to protocol: 'https://', from: params[:from]
      return
    end
  end
end
