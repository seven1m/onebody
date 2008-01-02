class DirectoryController < ApplicationController
  MAX_SELECT_PEOPLE = 5
  
  def index
    render :action => 'search'
  end
  
  def search
    params.reject_blanks!
    @search = Search.new_from_params(params)
    @people = @search.query(params[:page])
    @pages, @count = @search.pages, @search.count
    @show_birthdays = params[:birthday_month] or params[:birthday_day]
    @service_categories = Person.service_categories if @search.show_services
    respond_to do |wants|
      wants.html do
        redirect_to person_path(:id => @people.first) if @people.length == 1 and (params[:name] or params[:quick_name])
      end
      wants.js do
        render :update do |page|
          if params[:select_person]
            @people = @people[0..MAX_SELECT_PEOPLE]
            page.replace_html 'results', :partial => 'directory/select_person'
            page.show 'add_member'
          else
            page.replace_html 'results', :partial => 'directory/search_results'
          end
        end
      end
    end
  end
  
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
    
    pdf.add_image File.read(File.join(APP_OR_RAILS_ROOT, 'public/images/logo.png')), pdf.margin_x_middle - 120, pdf.absolute_top_margin - 200
    
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
      if family.mapable? or family.home_phone.to_i > 0
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
        if family.share_address_with(@logged_in) and family.mapable?
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
