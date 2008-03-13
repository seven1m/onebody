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
    
    if params[:generate]
      check_js = "setTimeout('new Ajax.Request(\"/directory/directory_to_pdf\", {parameters:\"generate=true\"})', 5000)"
      if job = session[:directory_pdf_job]
        if job.finished?
          session[:directory_pdf_job] = nil
          render :update do |page|
            if job.exit_status == 0
              page.replace_html('status', 'Success!<br/><br/>You should see your PDF pop up any second.')
              page.redirect_to :action => 'pickup_pdf'
            else
              page.replace_html('status', "There was an error generating your custom directory. Please notify the system administrator. Please provide this error message: <pre>#{job.stderr.to_s.gsub(/</, '&lt;').gsub(/>/, '&gt;')}</pre>")
            end
          end
        else
          render :update do |page|
            page.show('status')
            page.hide('generate_form')
            page << check_js
          end
        end
      else
        filename = File.join(RAILS_ROOT, 'tmp', @logged_in.id.to_s + '.pdf')
        session[:directory_pdf_job] = Bj.submit("./script/runner \"Site.current = Site.find(#{Site.current.id}); File.open('#{filename}', 'wb') { |f| f.write Person.find(#{@logged_in.id}).generate_directory_pdf }\"").first
        render :update do |page|
          page.show('status')
          page.hide('generate_form')
          page << check_js
        end
      end
    else
      render :action => 'creating_pdf'
    end
  end
  
  def pickup_pdf
    filename = File.join(RAILS_ROOT, 'tmp', @logged_in.id.to_s + '.pdf')
    if File.exists?(filename)
      pdf = File.read(filename)
      File.delete(filename)
      send_data pdf, :disposition => 'inline', :type => 'application/pdf', :filename => 'church_directory.pdf'
    else
      render :text => 'Sorry, we could not retrieve your custom directory. Either you already downloaded it or there was an error. You can try to have it generated again by <a href="directory_to_pdf">clicking here</a>. If this problem persists, please contact the system administrator.', :layout => true
    end
  end
  
  def select_for_nametags
    session[:select_for_nametags] = true
    redirect_to search_directory_url
  end
  
  def done_selecting_for_nametags
    session[:select_for_nametags] = false
    redirect_to nametags_url
  end
end
