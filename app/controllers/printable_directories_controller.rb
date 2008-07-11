class PrintableDirectoriesController < ApplicationController

  def new
    unless @logged_in.full_access?
      render :text => 'You are not allowed to print the directory. Sorry.', :layout => true, :status => 401
    end
  end
  
  def create
    filename = File.join(RAILS_ROOT, 'tmp', @logged_in.id.to_s + '.pdf')
    check_js = "setTimeout('new Ajax.Request(\"/printable_directory\", {parameters:\"generate=true\",method:\"post\"})', 5000)"
    if job_path = session[:directory_pdf_job]
      if not File.exists?(job_path)
        session[:directory_pdf_job] = nil
        render :update do |page|
          if File.exists?(filename)
            page.replace_html('status', 'Success!<br/><br/>You should see your PDF pop up any second.')
            page.redirect_to printable_directory_path
          else
            page.replace_html('status', "There was an error generating your custom directory. Please notify the system administrator.")
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
      job_path = File.join(DB_TASKS_PATH, 'now', @logged_in.id.to_s)
      cmd = "RAILS_ROOT/script/runner -e RAILS_ENV \"Site.current = Site.find(#{Site.current.id}); File.open('#{filename}.tmp', 'wb') { |f| f.write Person.find(#{@logged_in.id}).generate_directory_pdf }; File.rename('#{filename}.tmp', '#{filename}')\""
      begin
        File.open(job_path, 'w') { |f| f.write(cmd) }
        session[:directory_pdf_job] = job_path
        render :update do |page|
          page.show('status')
          page.hide('generate_form')
          page << check_js
        end
      rescue => e
        render(:update) { |p| p.alert('There was an error: ' + e.to_s) }
      end
    end
  end
  
  def show
    filename = File.join(RAILS_ROOT, 'tmp', @logged_in.id.to_s + '.pdf')
    if File.exists?(filename)
      pdf = File.read(filename)
      File.delete(filename)
      send_data pdf, :disposition => 'inline', :type => 'application/pdf', :filename => 'church_directory.pdf'
    else
      redirect_to new_printable_directory_path
    end
  end

end
