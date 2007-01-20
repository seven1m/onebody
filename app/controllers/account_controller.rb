class AccountController < ApplicationController
  def sign_in
    @email = cookies[:email]
    if request.post?
      if person = Person.authenticate(params[:email], params[:password])
        session[:logged_in_id] = person.id
        cookies[:email] = params[:remember] ? {:value => person.email, :expires => Time.now+32000000} : nil
        flash[:notice] = "Welcome, #{person.first_name}."
        redirect_to params[:from] || {:controller => 'people', :action => 'index'}
      elsif person == nil
        if family = Family.find_by_email(params[:email])
          flash[:notice] = 'That email address was found, but you must verify it before you can sign in.'
          redirect_to :action => 'verify_email', :email => params[:email]
        else
          flash[:notice] = 'That email address cannot be found in our system. Please try another email.'
        end
      else
        flash[:notice] = "The password you entered doesn't match our records. Please try again."
      end
    end
  end
  
  def sign_out
    session[:logged_in_id] = nil
    redirect_to :controller => 'people', :action => 'index'
  end
  
  def edit
    @person = Person.find params[:id]
    raise 'Error.' unless @logged_in.can_edit? @person or @logged_in.admin?
    if request.post?
      if params[:person][:email].to_s.any? and params[:person][:email] != @person.email
        @person.update_attributes :email => params[:person][:email], :email_changed => true
        if @person.errors.any?
          flash[:notice] = @person.errors.full_messages.join('; ')
        else
          flash[:notice] = 'Changes saved.'
          Notifier.deliver_email_update @person
        end
      end
      if @person.errors.empty? and (params[:person][:password].to_s.any? or params[:person][:password_confirmation].to_s.any?)
        @person.change_password params[:person][:password], params[:person][:password_confirmation]
        if @person.errors.any?
          flash[:notice] = @person.errors.full_messages.join('; ')
        else
          flash[:notice] = 'Changes saved.'
        end
      end
      if @person.errors.empty?
        redirect_to :controller => 'people', :action => 'view', :id => @person
      end
    end
  end
  
  def help
  end
  
  def safeguarding_children
  end
  
  def bad_status
  end
  
  def verify_email
    if params[:email].to_s.any?
      person = Person.find_by_email(params[:email])
      family = Family.find_by_email(params[:email])
      if person or family
        if (person and MAIL_GROUPS_CAN_LOG_IN.include? person.mail_group) or (family and family.people.any? and MAIL_GROUPS_CAN_LOG_IN.include? family.people.first.mail_group)
          v = Verification.create :email => params[:email]
          if v.errors.any?
            render :text => v.errors.full_messages.join('; '), :layout => true
          else
            Notifier.deliver_email_verification(v)
            render :text => 'The verification email has been sent. Please check your email and follow the instructions in the message you receive. (You may have to wait a minute or two for the email to arrive.)', :layout => true
          end
        else
          redirect_to :action => 'bad_status'
        end
      else
        flash[:notice] = "That email address could not be found in our system. If you have another address, try again."
      end
    end
  end
  
  def verify_mobile
    if request.post? and params[:mobile].to_s.any? and params[:carrier].to_s.any?
      mobile = params[:mobile].scan(/\d/).join('').to_i
      person = Person.find_by_mobile_phone(mobile)
      if person
        if MAIL_GROUPS_CAN_LOG_IN.include? person.mail_group
          unless gateway = MOBILE_GATEWAYS[params[:carrier]]
            raise 'Error.'
          end
          v = Verification.create :email => gateway % mobile, :mobile_phone => mobile
          if v.errors.any?
            render :text => v.errors.full_messages.join('; '), :layout => true
          else
            Notifier.deliver_mobile_verification(v)
            flash[:notice] = 'The verification message has been sent. Please check your phone and enter the code you receive.'
            redirect_to :action => 'verify_code', :id => v.id
          end
        else
          redirect_to :action => 'bad_status'
        end
      else
        flash[:notice] = "That mobile number could not be found in our system. You may try again."
      end
    end
  end
  
  def verify_birthday
    if request.post? 
      if params[:name].to_s.any? and params[:email].to_s.any? and params[:phone].to_s.any? and params[:birthday].to_s.any? and params[:notes].to_s.any?
        Notifier.deliver_birthday_verification(params)
        render :text => 'Your submission will be reviewed as soon as possible. You will receive an email once you have been approved.', :layout => true
      else
        flash[:notice] = 'You must complete all the required fields.'
      end
    end
  end
  
  def verify_code
    v = Verification.find params[:id]
    unless v.pending?
      render :text => 'There was an error.', :layout => true
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
          render :text => "Sorry. There was an error. If you requested the church office make a change, it's possible it just hasn't been done yet. Please try again later.", :layout => true
          return
        elsif @people.length == 1
          person = @people.first
          session[:logged_in_id] = person.id
          flash[:notice] = "You must set your personal email address#{v.mobile_phone ? '' : ' (it may be different than the one you verified)'} and password to continue."
          redirect_to :action => 'edit', :id => person.id
        else
          session[:select_from_people] = @people
          redirect_to :action => 'select_person'
        end
        v.update_attribute :verified, true
      else
        v.update_attribute :verified, false
        render :text => 'You entered the wrong code.', :layout => true
      end
    end
  end
  
  def select_person
    unless session[:select_from_people]
      render :text => 'This page is no longer valid.', :layout => true
      return
    end
    @people = session[:select_from_people]
    if request.post? and params[:id] and @people.map { |p| p.id }.include?(params[:id].to_i)
      session[:logged_in_id] = params[:id].to_i
      session[:select_from_people] = nil
      flash[:notice] = 'You must set your personal email address and password to continue.'
      redirect_to :action => 'edit', :id => session[:logged_in_id]
    end
  end
  
  # there's probably a better place for this, but we'll put it here for now
  def news_feed
    if NEWS_RSS_URL
      xml = Net::HTTP.get(URI.parse(NEWS_RSS_URL))
      root = REXML::Document.new(xml).root
      @headlines = root.elements.to_a('item').map do |item|
        [item.elements['title'].text, item.elements['link'].text]
      end
      render_without_layout
    else
      render :text => ''
    end
  end
end
