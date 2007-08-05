class PeopleController < ApplicationController
  def index
    @person = @logged_in
    @family = @person.family
    @prayer_signups = @person.prayer_signups.find(:all, :conditions => 'start >= curdate()', :order => 'start')
    @me = true
    if @logged_in.full_access?
      unless @person.visible?
        flash[:warning] = "<img src=\"/images/lock.gif\" class=\"no-border\"/> Your profile is hidden! <a href=\"#{url_for :action => 'privacy'}\">Click here</a> to change your privacy settings."
      end
      render :action => 'view'
    else
      render :action => 'limited_view'
    end
  end
  
  def view
    if @person = Person.find(params[:id]) rescue nil
      @family = @person.family
      @prayer_signups = @person.prayer_signups.find(:all, :conditions => 'start >= curdate()', :order => 'start')
      @me = (@logged_in == @person)
    end
    if not @person or not @logged_in.sees? @person
      render :text => 'Not found.', :status => 404
      return
    elsif not @logged_in.full_access? and @logged_in != @person
      render :action => 'limited_view'
    end
  end
  
  def blog
    @person = Person.find params[:id]
    if @logged_in.sees?(@person)
      @objects = @person.blog_items
      @pictures = @objects.select { |o| o.is_a? Picture }
      @non_pictures = @objects.select { |o| !o.is_a? Picture }
      render :partial => 'blog'
    else
      render :text => 'You are not authorized to view this person.', :layout => true
    end
  end
    
  def groups
    @person = Person.find params[:id]
    if @logged_in.sees?(@person)
      render :partial => 'groups'
    else
      render :text => 'You are not authorized to view this person.', :layout => true
    end
  end
  
  def recently
    if params[:id]
      unless @person = Person.find(params[:id]) and params[:code] == @person.feed_code
        render :text => 'There was an error getting this feed', :layout => true
        return false
      end
    else
      @person = @logged_in
    end
    friend_ids = [@person.id]
    friend_ids += @person.friends.find(:all, :select => 'people.id').map { |f| f.id } if SETTINGS['features']['friends']
    unless (group_ids = @person.groups.select { |g| !g.hidden? }.map { |g| g.id }).any?
      group_ids = [0]
    end
    @items = LogItem.find(
      :all,
      :conditions => ["((log_items.model_name in ('Friendship', 'Picture', 'Verse', 'Recipe', 'Person', 'Message', 'Note', 'Comment') and log_items.person_id in (#{friend_ids.join(',')})) or (log_items.model_name in ('Note', 'Message', 'PrayerRequest') and log_items.group_id in (#{group_ids.join(',')}))) and log_items.deleted = ? and (people.share_activity = ? or (people.share_activity is null and (select share_activity from families where id=people.family_id limit 1) = ?))", false, true, true],
      :order => 'log_items.created_at desc',
      :limit => 25,
      :include => :person
    ).select do |item|
      if item.model_name == 'Friendship'
        item.object.person != item.person
      elsif item.model_name == 'Message'
        (item.object.group and @person.groups.include? item.object.group) \
          or (item.object.wall and @person.friend? item.object.wall)
      elsif item.model_name == 'Person'
        item.showable_change_keys.any?
      else
        true
      end
    end
    # group nearby items
    @grouped_items = []
    last_model_name = nil
    group = nil
    @items.each do |item|
      if item.model_name != last_model_name or item.model_name != 'Picture'
        @grouped_items << group if group
        group = []
      end
      group << item
      last_model_name = item.model_name
    end
    @grouped_items << group if group
    respond_to do |wants|
      wants.html { render_without_layout }
      wants.js { render :partial => 'recently' }
    end
  end
  
  def simple_view(show_photo=false)
    @person = Person.find params[:id]
    @family = @person.family
    if not @logged_in.sees? @person
      render :text => 'You are not authorized to view this person.', :layout => true
    elsif not @logged_in.full_access?
      render :text => ''
    else
      @show_photo = show_photo
      render :action => 'simple_view', :layout => false
    end
  end
  
  def simple_photo_view
    simple_view(true)
  end
  
  def pictures
    @person = Person.find params[:id]
    if not @logged_in.sees?(@person)
      render :text => 'You are not authorized to view this person.', :layout => true
    end
  end
  
  def services
    @person = Person.find params[:id]
    if not @logged_in.sees?(@person)
      render :text => 'You are not authorized to view this person.', :layout => true
    end
  end
  
  def search_friends
    render :action => 'search'
  end
  
  def search
    @people = nil
    p = params.clone; p.delete 'action'; p.delete 'controller'
    if p.any?
      @show_birthdays = params[:birthday_month].to_s.any? or params[:birthday_day].to_s.any?
      conditions = []
      params[:name] = params.delete(:quick_name) if params[:quick_name]
      if params[:name].to_s.any?
        params[:name].gsub! /\sand\s/, ' & '
        conditions.add_condition ["(CONCAT(people.first_name, ' ', people.last_name) like ? or (#{params[:name].index('&') ? '1=1' : '1=0'} and families.name like ?) or (people.first_name like ? and people.last_name like ?))", "%#{params[:name]}%", "%#{params[:name]}%", "#{params[:name].split.first}%", "#{params[:name].split.last}%"]
      end
      if params[:service]
        @show_service = true
        conditions.add_condition ["people.service_name is not null and people.service_name != ''"]
        @service_categories = Person.find_by_sql("select distinct service_category from people where service_category is not null and service_category != '' order by service_category").map { |p| p.service_category }
      end
      if params[:category]
        conditions.add_condition ["people.service_category = ?", params[:category]]
      end
      if params[:testimony]
        conditions.add_condition ["people.testimony is not null and people.testimony != ''"]
      end
      if params[:family_id]
        conditions.add_condition ["people.family_id = ?", params[:family_id]]
      end
      unless @logged_in.admin?(:view_hidden_profiles) and params[:show_hidden]
        conditions.add_condition ["people.visible_to_everyone = ?", true]
        conditions.add_condition ["(people.visible = ? and families.visible = ?)", true, true]
      end
      conditions.add_condition ["DATE_ADD(people.birthday, INTERVAL 18 YEAR) <= CURDATE()"] unless @logged_in.full_access?
      conditions.add_condition ["MONTH(people.birthday) = ?", params[:birthday_month].to_i] if params[:birthday_month].to_s.any?
      conditions.add_condition ["DAY(people.birthday) = ?", params[:birthday_day].to_i] if params[:birthday_day].to_s.any?
      conditions.add_condition ["MONTH(people.anniversary) = ?", params[:anniversary_month].to_i] if params[:anniversary_month].to_s.any?
      conditions.add_condition ["DAY(people.anniversary) = ?", params[:anniversary_day].to_i] if params[:anniversary_day].to_s.any?
      conditions.add_condition ["LCASE(families.city) = ?", params[:city].downcase] if params[:city].to_s.any?
      conditions.add_condition ["LCASE(families.state) = ?", params[:state].downcase] if params[:state].to_s.any?
      conditions.add_condition ["families.zip like ?", "#{params[:zip]}%"] if params[:zip].to_s.any?
      conditions.add_condition ["people.member = ?", true] if params[:status].to_s.any?
      [:activities, :interests, :music, :tv_shows, :movies, :books].each do |favorite|
        conditions.add_condition ["people.#{favorite.to_s} like ?", "%#{params[favorite].downcase}%"] if params[favorite].to_s.any?
      end
      if conditions.any? or params[:browse]
        conditions = nil if conditions.empty?
        @count = Person.count :conditions => conditions, :include => :family
        @pages = Paginator.new self, @count, 100, params[:page]
        @people = Person.find(
          :all,
          :conditions => conditions,
          :include => :family,
          :order => (params[:service] ? 'people.service_name' : 'people.last_name, people.first_name'),
          :limit => @pages.items_per_page,
          :offset => @pages.current.offset
        ).select do |person| # ensure we don't show someone based on a search on an attribute that's private
          !person.nil? \
            and @logged_in.sees?(person) \
            and ((params[:birthday_month].to_s.empty? and params[:birthday_day].to_s.empty?) or person.share_birthday_with(@logged_in)) \
            and ((params[:anniversary_month].to_s.empty? and params[:anniversary_day].to_s.empty?) or person.share_anniversary_with(@logged_in)) \
            and ((params[:city].to_s.empty? and params[:state].to_s.empty? and params[:zip].to_s.empty?) or person.share_address_with(@logged_in)) \
            and (person.consent_or_13? or (@logged_in.admin?(:view_hidden_profiles) and params[:show_hidden]))
        end
      end
    end
    respond_to do |wants|
      wants.html do
        redirect_to :action => 'view', :id => @people.first if @people and @people.length == 1 and params[:name].to_s.any?
      end
      wants.js do
        render :update do |page|
          if params[:select_person]
            @people = @people[0..5]
            page.replace_html 'results', :partial => 'people/select_person'
            page.show 'add_member'
          else
            page.replace_html 'results', :partial => 'people/search_results'
          end
        end
      end
    end
  end
  
  def edit
    if params[:id]
      @person = Person.find params[:id]
      unless @logged_in.can_edit? @person
        render :text => "Sorry. You may not edit this person's profile.", :layout => true
        return
      end
    else
      @person = @logged_in
    end
    @family = @person.family
    @service_categories = Person.find_by_sql("select distinct service_category from people where service_category is not null and service_category != '' order by service_category").map { |p| p.service_category }
    if request.post?
      if @logged_in.frozen
        render :text => "Your account has been frozen due to misuse.", :layout => true
        return
      end
      if params[:photo_url] and params[:photo_url].length > 7
        @person.photo = params[:photo_url]
        flash[:refresh] = true
      elsif params[:photo]
        @person.photo = params[:photo] == 'remove' ? nil : params[:photo]
        flash[:refresh] = true
      elsif params[:person] and params[:person][:first_name]
        params[:person][:birthday] = params[:person][:birthday].to_date
        params[:person][:anniversary] = params[:person][:anniversary].to_date
        params[:person][:home_phone] = params[:person][:home_phone].scan(/\d/).join('')
        params[:person][:mobile_phone] = params[:person][:mobile_phone].scan(/\d/).join('')
        params[:person][:work_phone] = params[:person][:work_phone].scan(/\d/).join('')
        params[:person][:fax] = params[:person][:fax].scan(/\d/).join('')
        updates = keep_changes(params[:person], @person)
        updates[:birthday] = Date.new(1800, 1, 1) if updates.has_key?(:birthday) and updates[:birthday].nil?
        updates[:anniversary] = Date.new(1800, 1, 1) if updates.has_key?(:anniversary) and updates[:anniversary].nil?
        @person.updates.create(updates)
        Notifier.deliver_profile_update(@person, updates) if SETTINGS['contact']['send_updates_to']
        flash[:notice] = 'Changes submitted.'
      else # testimony, about, favorites, etc.
        if params[:person][:service_phone]
          params[:person][:service_phone] = params[:person][:service_phone].scan(/\d/).join('')
        end
        if @person.update_attributes params[:person]
          flash[:notice] = 'Changes saved.'
        else
          flash[:warning] = @person.errors.full_messages.join('; ')
        end
      end
      redirect_to :action => 'edit', :anchor => params[:anchor]
    end
  end
  
  def privacy
    if params[:id]
      @person = Person.find(params[:id])
    else
      @person = @logged_in
    end
    @family = @person.family
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
      redirect_to :action => 'privacy', :id => @person, :section => params[:anchor]
    end
  end
  
  def email
    @person = params[:id] ? Person.find(params[:id]) : @logged_in
    unless @logged_in.can_edit? @person
      render :text => 'You are not authorized to edit this person.'
      return
    end
    if request.post?
      if @person.update_attributes params[:person]
        flash[:notice] = 'Settings saved.'
        redirect_to :action => 'email', :id => @person
      else
        flash[:notice] = @person.errors.full_messages.join('; ')
      end
    end
  end
  
  # url looks like "/people/123.jpg" or "/people/123.small.jpg" or "/people/123.tn.jpg"
  def photo
    @person = Person.find params[:id].to_i
    if @logged_in.sees? @person
      send_photo @person
    else
      render :text => 'unauthorized to view this photo', :status => 404
    end
  end

  def freeze_account
    raise 'Unauthorized.' unless @logged_in.admin?(:edit_profiles)
    person = Person.find params[:id]
    person.update_attribute :frozen, !person.frozen
    redirect_to :action => 'edit', :id => params[:id]
  end
  
  # Contacts
  # ========
  
  def add_contact
    person = Person.find params[:id]
    if @logged_in.sees?(person) and @logged_in.contacts.find_all_by_person_id(person.id).empty?
      @logged_in.contacts.create :person => person
      @logged_in.reload
    end
    respond_to do |wants|
      wants.html do
        redirect_to :action => 'view', :id => params[:id]
      end
      wants.js do
        render :update do |page|
          page.visual_effect :fade, "add_contact_#{person.id}"
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
        redirect_to :action => 'view', :id => params[:id]
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
      redirect_to :action => 'view', :id => @logged_in
    else
      @logged_in.verses << verse unless @logged_in.verses.include? verse
      flash[:notice] = 'Verse saved.'
      if params[:event_id]
        redirect_to :controller => 'events', :action => 'view', :id => params[:event_id], :anchor => 'verses'
      else
        redirect_to :controller => 'verses', :action => 'view', :id => verse
      end
    end
  end

  def remove_verse
    verse = Verse.find params[:verse_id]
    verse.people.delete @logged_in
    flash[:notice] = 'Verse removed.'
    redirect_to params[:return_to] || {:action => 'view', :id => @logged_in, :anchor => 'shares'}
  end
      
  # Wall
  # ====
  
  def wall
    @person = Person.find params[:id]
    if @logged_in.sees?(@person)
      respond_to do |wants|
        wants.js { render :partial => 'wall' }
        wants.html
      end
    else
      render :text => 'You are not authorized to view this person.', :layout => true
    end
  end
  
  def wall_post
    person = Person.find params[:id]
    message = Message.create :person => @logged_in, :wall => person, :subject => 'Wall Post', :body => params[:message]
    flash[:notice] = 'Message saved.'
    redirect_to :action => 'view', :id => person, :anchor => 'wall'
  end
  
  def wall_to_wall
    @person = Person.find params[:id]
    @person2 = Person.find params[:id2]
    @messages = Message.find :all, :conditions => ['(wall_id = ? and person_id = ?) or (wall_id = ? and person_id = ?)', @person.id, @person2.id, @person2.id, @person.id], :order => 'created_at desc'
  end
  
  # Printed Directory
  # =================
  
  def directory_to_pdf
    unless @logged_in.full_access?
      render :text => 'You are not allowed to print the directory. Sorry.', :layout => true
      return
    end
    
    unless params[:generate]
      render :action => 'creating_pdf'
      return
    end
    
    pdf = PDF::Writer.new
    pdf.margins_pt 70, 20, 20, 20
    pdf.open_object do |heading|
      pdf.save_state
      pdf.stroke_color! Color::RGB::Black
      pdf.stroke_style! PDF::Writer::StrokeStyle::DEFAULT
      
      size = 24

      x = pdf.absolute_left_margin
      y = pdf.absolute_top_margin + 30
      pdf.add_text x, y, "#{SETTINGS['name']['church']} Directory\n\n", size

      x = pdf.absolute_left_margin
      w = pdf.absolute_right_margin
      #y -= (pdf.font_height(size) * 1.01)
      y -= 10
      pdf.line(x, y, w, y).stroke

      pdf.restore_state
      pdf.close_object
      pdf.add_object(heading, :all_following_pages)
    end

    s = 24
    w = pdf.text_width('Directory', s)
    x = pdf.margin_x_middle - w/2 # centered
    y = pdf.margin_y_middle - pdf.margin_height/4 # below center
    pdf.add_text x, y, 'Directory', s
    
    pdf.add_image File.read(File.join(RAILS_ROOT, 'public/images/logo.png')), pdf.margin_x_middle - 120, pdf.absolute_top_margin - 200
    
    t = "Created especially for #{@logged_in.name} on #{Date.today.strftime '%B %e, %Y'}"
    s = 14
    w = pdf.text_width(t, s)
    x = pdf.margin_x_middle - w/2 # centered
    y = pdf.margin_y_middle - pdf.margin_height/3 # below center
    pdf.add_text x, y, t, s
    
    pdf.start_new_page
    pdf.start_columns
    
    alpha = nil
    
    Family.find(
      :all,
      :conditions => ["(select count(*) from people where family_id = families.id and visible_on_printed_directory = ?) > 0", true],
      :order => 'families.last_name, families.name, people.sequence',
      :include => 'people'
    ).each do |family|
      if (family.address1.to_s.any? and family.city.to_s.any? and family.state.to_s.any? and family.zip.to_s.any?) or family.home_phone.to_i > 0
        pdf.move_pointer 120 if pdf.y < 120
        if family.last_name[0..0] != alpha
          pdf.move_pointer 150 if pdf.y < 150
          alpha = family.last_name[0..0]
          pdf.text alpha + "\n", :font_size => 25
          pdf.line(
            pdf.absolute_left_margin,
            pdf.y - 5,
            pdf.absolute_left_margin + pdf.column_width - 25,
            pdf.y - 5
          ).stroke
          pdf.move_pointer 10
        end
        pdf.text family.name + "\n", :font_size => 18
        if family.people.length > 2
          p = family.people.map do |p|
            p.last_name == family.last_name ? p.first_name : p.name
          end.join(', ')
          pdf.text p + "\n", :font_size => 11
        end
        if family.share_address_with(@logged_in) and family.address1.to_s.any? and family.city.to_s.any? and family.state.to_s.any? and family.zip.to_s.any?
          pdf.text family.address1 + "\n", :font_size => 14
          pdf.text family.address2 + "\n" if family.address2.to_s.any?
          pdf.text family.city + ', ' + family.state + '  ' + family.zip + "\n"
        end
        pdf.text number_to_phone(family.home_phone, :area_code => true), :font_size => 14 if family.home_phone.to_i > 0
        pdf.text "\n"
      end
    end
    
    send_data pdf.to_s, :disposition => 'inline', :type => 'application/pdf', :filename => 'church_directory.pdf'
  end
  
  private
  
    def keep_changes(updates, person)
      updates.delete_if do |key, value|
        value.to_s == person.send(key).to_s.gsub(/\s00:00:00$/, '')
      end
    end
end
