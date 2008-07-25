class PrintableDirectoriesController < ApplicationController

  def new
    unless @logged_in.full_access?
      render :text => 'You are not allowed to print the directory. Sorry.', :layout => true, :status => 401
    end
  end
  
  def create
    filename = File.join(RAILS_ROOT, 'tmp', @logged_in.id.to_s + '.pdf')
    check_js = "setTimeout('new Ajax.Request(\"/printable_directory\", {parameters:\"generate=true\",method:\"post\"})', 5000)"
    if task_id = session[:directory_pdf_job]
      if not ScheduledTask.find_by_id(task_id)
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
      begin
        task = ScheduledTask.queue(
          "Printed Directory for #{@logged_in.name} (#{@logged_in.id})",
          "File.open('#{filename}.tmp', 'wb') { |f| f.write Person.find(#{@logged_in.id}).generate_directory_pdf }; File.rename('#{filename}.tmp', '#{filename}')"
        )
        session[:directory_pdf_job] = task.id
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
