class PeopleController < ApplicationController
  def index
    @person = @logged_in
    @family = @person.family
    if @logged_in.member?
      render :action => 'view'
    else
      render :action => 'limited_view'
    end
  end
  
  def view
    @person = Person.find params[:id]
    @family = @person.family
    if not @logged_in.sees? @person
      render :text => 'You are not authorized to view this person.', :layout => true
    elsif not @logged_in.member?
      render :action => 'limited_view'
    end
  end
  
  def simple_view(show_photo=false)
    @person = Person.find params[:id]
    @family = @person.family
    if not @logged_in.sees? @person
      render :text => 'You are not authorized to view this person.', :layout => true
    elsif not @logged_in.member?
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
  
  def search
    @people = nil
    p = params.clone; p.delete 'action'; p.delete 'controller'
    if p.any?
      @show_birthdays = params[:birthday_month].to_s.any? or params[:birthday_day].to_s.any?
      conditions = []
      params[:name] = params.delete(:quick_name) if params[:quick_name]
      if params[:name].to_s.any?
        conditions.add_condition ["CONCAT(people.first_name, ' ', people.last_name) like ?", "%#{params[:name]}%"]
      end
      if params[:service]
        @show_service = true
        conditions.add_condition ["people.service_name is not null and people.service_name != ''"]
      end
      conditions.add_condition ["DATE_ADD(people.birthday, INTERVAL 18 YEAR) <= CURDATE()"] unless @logged_in.member?
      conditions.add_condition ["MONTH(people.birthday) = ?", params[:birthday_month].to_i] if params[:birthday_month].to_s.any?
      conditions.add_condition ["DAY(people.birthday) = ?", params[:birthday_day].to_i] if params[:birthday_day].to_s.any?
      conditions.add_condition ["MONTH(families.anniversary) = ?", params[:anniversary_month].to_i] if params[:anniversary_month].to_s.any?
      conditions.add_condition ["DAY(families.anniversary) = ?", params[:anniversary_day].to_i] if params[:anniversary_day].to_s.any?
      conditions.add_condition ["LCASE(families.city) = ?", params[:city].downcase] if params[:city].to_s.any?
      conditions.add_condition ["LCASE(families.state) = ?", params[:state].downcase] if params[:state].to_s.any?
      conditions.add_condition ["families.zip like ?", "#{params[:zip]}%"] if params[:zip].to_s.any?
      conditions.add_condition "LCASE(people.mail_group) = 'M'" if params[:status].to_s.any?
      [:activities, :interests, :music, :tv_shows, :movies, :books].each do |favorite|
        conditions.add_condition ["people.#{favorite.to_s} like ?", "%#{params[favorite].downcase}%"] if params[favorite].to_s.any?
      end
      if conditions.any? or params[:browse]
        conditions = nil if conditions.empty?
        @count = Person.count :conditions => conditions, :include => :family
        @pages = Paginator.new self, @count, 100, params[:page]
        @people = Person.find :all,
          :conditions => conditions,
          :include => :family,
          :order => 'people.last_name, people.first_name',
          :limit => @pages.items_per_page,
          :offset => @pages.current.offset
        # ensure we don't show something that's private
        @people = @people.select do |person|
          return false if person.nil?
          return false if (params[:birthday_month].to_s.any? or params[:birthday_day].to_s.any?) and not person.share_birthday_with(@logged_in)
          return false if (params[:anniversary_month].to_s.any? or params[:anniversary_day].to_s.any?) and not person.share_anniversary_with(@logged_in)
          return false if (params[:city].to_s.any? or params[:state].to_s.any? or params[:zip].to_s.any?) and not person.share_address_with(@logged_in)
          true
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
      raise 'Error.' unless @logged_in.can_edit? @person
    else
      @person = @logged_in
    end
    @family = @person.family
    if request.post?
      if params[:photo_url] and params[:photo_url].length > 7
        @person.photo = params[:photo_url]
      elsif params[:photo]
        @person.photo = params[:photo] == 'remove' ? nil : params[:photo]
      elsif params[:person] and params[:person][:first_name]
        Notifier.deliver_profile_update @person, params[:person]
        flash[:notice] = 'Changes submitted.'
      else # testimony, about, favorites, etc.
        if params[:person][:website] and params[:person][:website] !~ /^http:\/\//
          params[:person][:website] = 'http://' + params[:person][:website]
        end
        @person.update_attributes params[:person]
        flash[:notice] = 'Changes saved.'
      end
      redirect_to :action => 'edit'
    end
  end
  
  def privacy
    @family = @logged_in.family
    if request.post?
      if not @logged_in.adult?
        render_message "Only an adult can edit privacy settings."
      elsif params[:person]
        if person = @family.people.find(params[:id])
          params[:person].each { |k, v| params[:person][k] = (v == 'nil') ? nil : v } 
          person.update_attributes params[:person]
          @logged_in.reload
          render_message "Personal settings saved for #{person.name}."
        end
      elsif params[:family]
        @family.update_attributes params[:family]
        render_message "Family settings saved."
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
  
  def add_contact
    person = Person.find params[:id]
    if @logged_in.sees?(person) and @logged_in.contacts.find_all_by_person_id(person.id).empty?
      @logged_in.contacts.create :person => person
      @logged_in.reload
    end
    redirect_to :action => 'view', :id => params[:id]
  end
  
  def remove_contact
    if contact = @logged_in.contacts.find_by_person_id(params[:id])
      contact.destroy
      @logged_in.reload
    end
    redirect_to :action => 'view', :id => params[:id]
  end
  
  def directory_to_pdf
    unless @logged_in.member?
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
      pdf.add_text x, y, "#{CHURCH_NAME} Directory\n\n", size

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
      :conditions => ["families.mail_group in ('M', 'A')"],
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
end
