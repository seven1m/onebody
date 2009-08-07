class AccountsController < ApplicationController
  filter_parameter_logging :password
  
  before_filter :check_ssl, :except => [:verify]
  skip_before_filter :authenticate_user, :except => %w(edit update)
  
  cache_sweeper :person_sweeper, :family_sweeper, :only => %w(create update)
  
  def show
    if params[:person_id]
      redirect_to person_account_path(params[:person_id])
    else
      redirect_to new_account_path
    end
  end

  def new
    if params[:email]
      render :action => 'new_by_email'
    elsif params[:mobile]
      render :action => 'new_by_mobile'
    elsif params[:birthday]
      render :action => 'new_by_birthday'
    elsif Setting.get(:features, :sign_up)
      @person = Person.new
    end
  end
  
  def create
    if params[:person] and Setting.get(:features, :sign_up) and params[:phone].blank? # phone is to catch bots (hidden field)
      if Person.find_by_email(params[:person][:email])
        params[:email] = params[:person][:email]
        create_by_email
      else
        attributes = {:can_sign_in => false, :full_access => false, :visible_to_everyone => false}
        attributes.merge! params[:person].reject { |k, v| !%w(email first_name last_name gender).include?(k) }
        @person = Person.create(attributes)
        if @person.valid?
          @person.family = Family.create(:name => @person.name, :last_name => @person.last_name)
          if Setting.get(:features, :sign_up_approval_email).to_s.any?
            @person.save
            Notifier.deliver_pending_sign_up(@person)
            render :text => "Your account is pending approval. You will receive an email once it's approved.", :layout => true
          else
            @person.update_attributes!(:can_sign_in => true, :full_access => true, :visible_to_everyone => true, :visible_on_printed_directory => true)
            params[:email] = @person.email
            create_by_email
          end
        else
          render :action => 'new'
        end
      end
    elsif params[:name].to_s.any? and params[:email].to_s.any? and params[:phone].to_s.any? and params[:birthday].to_s.any? and params[:notes].to_s.any?
      create_by_birthday
    elsif params[:mobile].to_s.any? and params[:carrier].to_s.any?
      create_by_mobile
    elsif params[:email].to_s.any?
      create_by_email
    else
      flash[:warning] = 'Please fill in all required fields.'
      render :action => 'new'
    end
  end
  
  private
  
    def create_by_email
      person = Person.find_by_email(params[:email])
      family = Family.find_by_email(params[:email])
      if person or family
        if (person and person.can_sign_in?) or (family and family.people.any? and family.people.first.can_sign_in?)
          v = Verification.create :email => params[:email]
          if v.errors.any?
            render :text => v.errors.full_messages.join('; '), :layout => true
          else
            Notifier.deliver_email_verification(v)
            render :text => 'The verification email has been sent. Please check your email and follow the instructions in the message you receive. (You may have to wait a minute or two for the email to arrive.)', :layout => true
          end
        else
          redirect_to page_for_public_path('system/bad_status')
        end
      else
        flash[:warning] = "That email address could not be found in our system. If you have another address, try again."
        render :action => 'new'
      end
    end
  
    def create_by_mobile
      mobile = params[:mobile].scan(/\d/).join('')
      person = Person.find_by_mobile_phone(mobile)
      if person
        if person.can_sign_in?
          unless gateway = MOBILE_GATEWAYS[params[:carrier]]
            raise 'Error.'
          end
          v = Verification.create :email => gateway % mobile, :mobile_phone => mobile
          if v.errors.any?
            render :text => v.errors.full_messages.join('; '), :layout => true
          else
            Notifier.deliver_mobile_verification(v)
            flash[:warning] = 'The verification message has been sent. Please check your phone and enter the code you receive.'
            redirect_to verify_code_account_path(:id => v.id)
          end
        else
          redirect_to page_for_public_path('system/bad_status')
        end
      else
        flash[:warning] = "That mobile number could not be found in our system. You may try again."
        render :action => 'new'
      end
    end
  
    def create_by_birthday
      if params[:name].to_s.any? and params[:email].to_s.any? and params[:phone].to_s.any? and params[:birthday].to_s.any? and params[:notes].to_s.any?
        Notifier.deliver_birthday_verification(params)
        render :text => 'Your submission will be reviewed as soon as possible. You will receive an email once you have been approved.', :layout => true
      else
        flash[:warning] = 'You must complete all the required fields.'
        render :action => 'new'
      end
    end

  public
  
  def verify_code
    v = Verification.find(params[:id])
    unless v.pending?
      render :text => 'There was an error.', :layout => true, :status => 500
      return
    end
    if params[:code].to_i > 0
      if v.code == params[:code].to_i
        if v.mobile_phone
          conditions = ['people.mobile_phone = ?', v.mobile_phone]
        else
          conditions = ['people.email = ? or families.email = ?', v.email, v.email]
        end
        @people = Person.find :all, :conditions => conditions, :include => :family
        if @people.nil? or @people.empty?
          render :text => "Sorry. There was an error. If you requested the office make a change, it's possible it just hasn't been done yet. Please try again later.", :layout => true, :status => 500
          return
        elsif @people.length == 1
          person = @people.first
          session[:logged_in_id] = person.id
          flash[:warning] = "You must set your personal email address#{v.mobile_phone ? '' : ' (it may be different than the one you verified)'} and password to continue."
          redirect_to edit_person_account_path(person.id)
        else
          session[:select_from_people] = @people
          redirect_to select_account_path
        end
        v.update_attribute :verified, true
      else
        v.update_attribute :verified, false
        render :text => 'You entered the wrong code.', :layout => true, :status => 500
      end
    end
  end
  
  def edit
    @person ||= Person.find(params[:person_id])
    if @logged_in.can_edit?(@person)
      generate_encryption_key
    else
      render :text => 'You cannot edit this account.', :layout => true, :status => 401
    end
  end
  
  def update
    @person = Person.find(params[:person_id])
    if @logged_in.can_edit?(@person)
      if Rails.env == 'test' and params[:password]
        password = params[:password]
        password_confirmation = params[:password_confirmation]
      else
        password = decrypt_password(params[:encrypted_password])
        password_confirmation = decrypt_password(params[:encrypted_password_confirmation])
      end
      @person.attributes = params[:person]
      @person.email_changed = @person.changed.include?('email')
      @person.save
      if @person.errors.any?
        edit; render :action => 'edit'
      elsif password.to_s.any? or password_confirmation.to_s.any?
        @person.change_password(password, password_confirmation)
        if @person.errors.any?
          edit; render :action => 'edit'
        else
          flash[:notice] = 'Changes saved.'
          redirect_to @person
        end
      else
        flash[:notice] = 'Changes saved.'
        redirect_to @person
      end
    else
      render :text => 'You cannot edit this account.', :layout => true, :status => 401
    end
  end
  
  def select
    unless session[:select_from_people]
      render :text => 'This page is no longer valid.', :layout => true
      return
    end
    @people = session[:select_from_people]
    if request.post? and params[:id] and @people.map { |p| p.id }.include?(params[:id].to_i)
      session[:logged_in_id] = params[:id].to_i
      session[:select_from_people] = nil
      flash[:warning] = 'You must set your personal email address and password to continue.'
      redirect_to edit_person_account_path(session[:logged_in_id])
    end
  end
  
  private
    def check_ssl
      unless request.ssl? or RAILS_ENV != 'production' or !Setting.get(:features, :ssl)
        redirect_to :protocol => 'https://', :from => params[:from]
        return
      end
    end
end
