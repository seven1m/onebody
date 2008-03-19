class NametagsController < ApplicationController
  before_filter :check_access
  
  def index
    @selected = session[:nametag_selections].to_a
  end
  
  def add
    session[:nametag_selections] ||= []
    if @person = Person.find(params[:id]) \
      and not session[:nametag_selections].include? @person
      session[:nametag_selections] << @person
    end
    respond_to do |format|
      format.js
    end
  end
  
  def remove
    if @person = Person.find(params[:id])
      session[:nametag_selections].delete @person
    end
    redirect_to nametags_url
  end
  
  def barcode
    @person = Person.find(params[:id])
    if @person.barcode_id
      img = Barcode.new(@person.barcode_id).to_jpg
      send_data img, :type => 'image/jpeg', :disposition => 'inline'
    else
      render :text => 'No barcode ID for this person.', :status => :missing
    end
  end
  
  def print
    testing = true
    pdf = PDF::Writer.new
    pdf.margins_pt 20, 330, 20, 20
    bg = File.open(File.join(RAILS_ROOT, 'public/images/nametags.jpg'), 'rb')
    bg_img = bg.read
    bg.close
    @selected = session[:nametag_selections].to_a.sort_by &:name
    @selected.in_groups_of(3).each_with_index do |people, page_number|
      pdf.start_new_page unless page_number == 0
      pdf.add_image bg_img, 0, 0 if testing
      people.select { |p| p and p.barcode_id }.each_with_index do |person, index|
        x = 330
        y = {0 => 696, 1 => 434, 2 => 164}[index]
        # name
        pdf.add_text x, y, person.first_name, 28
        pdf.add_text x, y-20, person.last_name, 18
        # barcode
        pdf.add_image Barcode.new(person.barcode_id).to_jpg, x, y-90, nil, 60
        # birthday
        if person.birthday
          x = 530 - pdf.text_width(t = person.birthday.strftime('%B'), s = 10)
          pdf.add_text x, y, t, s
          x = 530 - pdf.text_width(t = person.birthday.strftime('%Y'), s = 20)
          pdf.add_text x, y-18, t, s
        end
        # family name
        x = 530 - pdf.text_width(t = person.family.name, s = 9)
        pdf.add_text x, y-50, t, s
        # family mobile phone numbers
        person.parent_mobile_phones.each_with_index do |phone, phone_index|
          x = 530 - pdf.text_width(t = phone, s = 8)
          pdf.add_text x, y-60-(phone_index*10), t, s
        end
      end
    end

    send_data pdf, :type => 'application/pdf', :disposition => 'inline', :filename => 'nametags.pdf'
  end

  private
    def check_access
      unless @logged_in.admin?(:manage_checkin)
        render :text => 'This section is only available to authorized users.', :layout => true
        return false
      end
    end
end
