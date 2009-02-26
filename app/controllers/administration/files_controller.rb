class Administration::FilesController < ApplicationController

  before_filter :only_admins
  before_filter :get_path

  def index
    @files = Dir[@path + '/*'].map do |file|
      {:filename => File.split(file).last, :url => "/assets/site#{Site.current.id}/#{File.split(file).last}", :size => File.stat(file).size}
    end
  end
  
  def create
    if params[:filename] =~ /^[a-z0-9_]+(\.[a-z0-9_]+)?$/
      File.open(@path + '/' + params[:filename], 'wb') do |file|
        file.write(params[:file].read)
      end
      redirect_to administration_files_path
    else
      render :text => 'Filename contains invalid characters.', :layout => true, :status => 500
    end
  end
  
  def destroy
    if params[:id] =~ /^[a-z0-9_]+(\.[a-z0-9_]+)?$/
      begin
        File.delete(@path + '/' + params[:id])
      rescue
        render :text => 'File not found.', :layout => true, :status => 404
      end
      redirect_to administration_files_path
    else
      render :text => 'Filename contains invalid characters.', :layout => true, :status => 500
    end
  end
  
  private
  
  def get_path
    @path = "#{Rails.root}/public/assets/site#{Site.current.id}"
    unless File.exist?(@path)
      FileUtils.mkdir_p(@path)
    end
  end

end
