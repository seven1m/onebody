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
    if params[:email]
      render action: 'new_by_email'
    elsif params[:phone]
      render action: 'new_by_mobile'
    elsif params[:birthday]
      render action: 'new_by_birthday'
    elsif Setting.get(:features, :sign_up)
      @person = Person.new
    end
  end

  def create
    if params[:person] and Setting.get(:features, :sign_up) and params[:phone].blank? # phone is to catch bots (hidden field)
      if params[:person][:email].to_s.any?
        if Person.find_by_email(params[:person][:email])
          params[:email] = params[:person][:email]
          create_by_email
        else
          attributes = {can_sign_in: false, full_access: false, visible_to_everyone: false}
          attributes.merge! params[:person].reject { |k, v| !%w(email first_name last_name gender birthday).include?(k) }
          @person = Person.new(attributes)
          if @person.adult?
            if @person.save
              @person.family = Family.create(name: @person.name, last_name: @person.last_name)
              if Setting.get(:features, :sign_up_approval_email).to_s.any?
                @person.save
                Notifier.pending_sign_up(@person).deliver
                render text: t('accounts.pending_approval'), layout: true
              else
                @person.update_attributes!(can_sign_in: true, full_access: true, visible_to_everyone: true, visible_on_printed_directory: true)
                params[:email] = @person.email
                create_by_email
              end
            else
              render action: 'new'
            end
          else
            @person.errors.add(:base, t('accounts.must_be_of_age', years: Setting.get(:system, :adult_age)))
            render action: 'new'
          end
        end
      else
        @person = Person.new
        @person.errors.add(:email, :invalid)
        render action: 'new'
      end
    elsif params[:name].to_s.any? and params[:email].to_s.any? and params[:phone].to_s.any? and params[:birthday].to_s.any? and params[:notes].to_s.any?
      create_by_birthday
    elsif params[:phone].to_s.any? and params[:carrier].to_s.any?
      create_by_mobile
    elsif params[:email].to_s.any?
      create_by_email
    else
      @person = Person.new
      flash[:warning] = t('accounts.fill_required_fields')
      render action: 'new'
    end
  end

  private

    def create_by_email
      person = Person.find_by_email(params[:email])
      family = Family.find_by_email(params[:email])
      if person or family
        if (person and person.can_sign_in?) or (family and family.people.any? and family.people.first.can_sign_in?)
          v = Verification.create email: params[:email]
          if v.errors.any?
            render text: v.errors.full_messages.join('; '), layout: true
          else
            Notifier.email_verification(v).deliver
            render text: t('accounts.verification_email_sent'), layout: true
          end
        else
          redirect_to page_for_public_path('system/bad_status')
        end
      else
        render text: t('accounts.email_not_found'), layout: true
      end
    end

    def create_by_mobile
      mobile = params[:phone].scan(/\d/).join('')
      person = Person.find_by_mobile_phone(mobile)
      if person
        if person.can_sign_in?
          unless gateway = MOBILE_GATEWAYS[params[:carrier]]
            raise 'Error.'
          end
          v = Verification.create email: gateway % mobile, mobile_phone: mobile
          if v.errors.any?
            render text: v.errors.full_messages.join('; '), layout: true
          else
            Notifier.mobile_verification(v).deliver
            render text: t('accounts.verification_message_sent'), layout: true
          end
        else
          redirect_to page_for_public_path('system/bad_status')
        end
      else
        flash[:warning] = t('accounts.mobile_number_not_found')
        @person = Person.new
        render action: 'new'
      end
    end

    def create_by_birthday
      if params[:name].to_s.any? and params[:email].to_s.any? and params[:phone].to_s.any? and params[:birthday].to_s.any? and params[:notes].to_s.any?
        Notifier.birthday_verification(params[:name], params[:email], params[:phone], params[:birthday], params[:notes]).deliver
        render text: t('accounts.submission_will_be_reviewed'), layout: true
      else
        flash[:warning] = t('accounts.fill_required_fields')
        @person = Person.new
        render action: 'new'
      end
    end

  public

  def verify_code
    v = Verification.pending.find(params[:id])
    if v.check!(params[:code])
      if v.people.count > 1
        session[:select_from_people] = v.people.all
        redirect_to select_account_path
      else
        person = v.people.first
        session[:logged_in_id] = person.id
        flash[:sticky_notice] = true
        if v.mobile_phone?
          flash[:warning] = t('accounts.set_your_email')
        else
          flash[:warning] = t('accounts.set_your_email_may_be_different')
        end
        redirect_to edit_person_account_path(person)
      end
    else
      render text: t('accounts.wrong_code'), layout: true, status: :bad_request
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
