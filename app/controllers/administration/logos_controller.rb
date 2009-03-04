class Administration::LogosController < ApplicationController

  before_filter :only_admins
  before_filter :get_path
  
  def show
    @filename = Setting.get(:appearance, :logo)
  end
  
  def create
    unless params[:file].to_s.blank?
      if img = MiniMagick::Image.from_blob(params[:file].read) rescue nil \
      and ending = {'JPEG' => 'jpg', 'GIF' => 'gif', 'PNG' => 'png'}[img['format']]
        filename = "logo.#{ending}"
        img.thumbnail('400x80') if img['width'] > 400 or img['height'] > 80
        img.write("#{@path}/#{filename}")
        Setting.set(Site.current.id, 'Appearance', 'Logo', filename)
      end
    end
    redirect_to administration_logo_path
  end
  
  def destroy
    if Setting.get(:appearance, :logo).to_s.any?
      filename = "#{@path}/#{Setting.get(:appearance, :logo)}"
      File.delete(filename) if File.exist?(filename)
      Setting.set(Site.current.id, 'Appearance', 'Logo', nil)
    end
    redirect_to administration_logo_path
  end
  
  private
  
  def get_path
    @path = "#{Rails.root}/public/assets/site#{Site.current.id}"
    unless File.exist?(@path)
      FileUtils.mkdir_p(@path)
    end
  end
  
end
