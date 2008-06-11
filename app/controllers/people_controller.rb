class PeopleController < ApplicationController
  before_filter :get_person, :except => [:index, :search, :directory_to_pdf, :add_verse, :remove_verse]
  before_filter :can_see?, :except => [:recently, :index, :search, :directory_to_pdf, :add_verse, :remove_verse]
  before_filter :can_edit?, :only => [:email, :edit]
  
  def recently # backwards compatibility with old RSS feed links
    redirect_to formatted_feed_path('rss', :code => params[:code])
  end
  
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  
  def index; @person = @logged_in; @family = @person.family; view; end
  
  def view
    if @person
      @prayer_signups = @person.prayer_signups.find(:all, :conditions => ['start >= ?', Time.now], :order => 'start')
      @family_people = @person.family.visible_people
      @me = (@logged_in == @person)
      @show_map = Setting.get(:services, :yahoo) and @person.family.mapable? and @person.share_address_with @logged_in
      render :action => (@logged_in.full_access? or @me) ? 'view' : 'limited_view'
    else
      render :text => 'Not found.', :status => 404
    end
  end
  
  def groups; render(:partial => 'groups'); end
  
  def simple_view(show_photo=false)
    if not @logged_in.full_access?
      render :text => ''
    else
      render :action => (show_photo ? 'simple_photo_view.html.erb' : 'simple_view.html.erb'), :layout => false
    end
  end
  
  def simple_photo_view; simple_view(true); end
  
  def pictures
  end
  
  def services
  end
  
  def edit
    @service_categories = Person.find_by_sql("select distinct service_category from people where service_category is not null and service_category != '' order by service_category").map { |p| p.service_category }
    @can_edit_basics = Setting.get(:features, :standalone_use) && @logged_in.admin?(:edit_profiles)
    if request.post?
      if @logged_in.account_frozen?
        render :text => "Your account has been frozen due to misuse.", :layout => true
        return
      end
      if updated = @person.update_from_params(params, @can_edit_basics)
        flash[:refresh] = true if updated == 'photo'
        flash[:notice] = 'Changes saved.'
      else
        flash[:warning] = @person.errors.full_messages.join('; ')
      end
      redirect_to edit_profile_path(:id => @person, :anchor => params[:anchor])
    end
  end
  
  def delete
    if request.post? and Setting.get(:features, :standalone_use) and @logged_in.admin?(:edit_profiles)
      family = Person.find(params[:id]).destroy.family
      redirect_to params[:return_to] || family_path(:id => family)
    end
  end
  
  def privacy
    if params[:consent] and child = @family.children_without_consent.first
      redirect_to :anchor => "p#{child.id}"
      return
    end
    unless @family.visible?
      flash[:warning] = "#{@family == @logged_in.family ? 'Your' : 'This'} family is currently hidden from all pages on this site!"
    end
    if request.post?
      if not @logged_in.can_edit? @family
        render_message "You may not edit these settings. Sorry."
        return
      elsif params[:person]
        if person = @family.people.find(params[:id])
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
        if person = @family.people.find(params[:id])
          @person.parental_consent = "#{@logged_in.name} (#{@logged_in.id}) at #{Time.now.to_s}"
          @person.save
          flash[:notice] = 'Agreement saved.'
        end
      elsif params[:commit] == 'I Agree'
        flash[:warning] = 'You must check the box indicating you agree to the statement below.'
      end
      redirect_to person_privacy_path(@person, :section => params[:anchor])
    end
  end
  
  def email
    if request.post?
      if @person.update_attributes params[:person]
        flash[:notice] = 'Settings saved.'
        redirect_to person_email_prefs_path(@person)
      else
        flash[:notice] = @person.errors.full_messages.join('; ')
      end
    end
  end
  
  # url looks like "/people/123.jpg" or "/people/123.small.jpg" or "/people/123.tn.jpg"
  def photo; send_photo @person; end

  def freeze_account
    raise 'Unauthorized.' unless @logged_in.admin?(:edit_profiles)
    @person.toggle! :frozen
    redirect_to edit_person_path(params[:id])
  end
  
  # Contacts
  # ========
  
  def add_contact
    if @logged_in.sees?(@person) and @logged_in.contacts.find_all_by_person_id(@person.id).empty?
      @logged_in.contacts.create :person => @person
      @logged_in.reload
    end
    respond_to do |wants|
      wants.html do
        redirect_to person_path(params[:id])
      end
      wants.js do
        render :update do |page|
          page.visual_effect :fade, "add_contact_#{@person.id}"
        end
      end
    end
  end
  
  def remove_contact
    if contact = @logged_in.contacts.find_by_person_id(params[:id])
      contact.destroy
      @logged_in.reload
    end
    respond_to do |wants|
      wants.html do
        redirect_to person_path(params[:id])
      end
      wants.js do
        render :update do |page|
          page << "$('contact_#{params[:id]}').style.textDecoration = 'line-through'"
          page.visual_effect :fade, "contact_spinner_#{params[:id]}"
          page.remove "remove_contact_#{params[:id]}"
        end
      end
    end
  end
  
  # Verses
  # ======
  
  def add_verse
    verse = Verse.find_or_create_by_reference(Verse.normalize_reference(params[:reference]))
    if params[:event_id]
      verse.events << Event.find(params[:event_id])
      verse.save
    end
    if verse.errors.any?
      flash[:notice] = 'There was an error adding the verse. Make sure you entered the right reference.'
      redirect_to person_path(@logged_in)
    else
      @logged_in.verses << verse unless @logged_in.verses.include? verse
      flash[:notice] = 'Verse saved.'
      if params[:event_id]
        redirect_to event_path(params[:event_id], :anchor => 'verses')
      else
        redirect_to verse_path(verse)
      end
    end
  end

  def remove_verse
    verse = Verse.find(params[:verse_id])
    verse.people.delete @logged_in
    flash[:notice] = 'Verse removed.'
    redirect_to params[:return_to] || person_path(@logged_in, :anchor => 'shares')
  end
      
  def opensearch
    render :layout => false, :content_type => Mime::XML
  end
  
  private
  
  def get_person
    if params[:id]
      @person = Person.find_by_id(params[:id].to_i)
    else
      @person = @logged_in
      @me = true
    end
    @family = @person.family if @person
  end
  
  def can_see?
    if @person and not @logged_in.can_see? @person
      return render_no_auth
    end
  end
  
  def can_edit?
    unless @logged_in.can_edit? @person
      render :text => "Sorry. You may not edit this person's profile.", :layout => true
      return false
    end
  end
  
  def render_no_auth
    render :text => 'You are not authorized to view this person.', :layout => true
    return false
  end
end
