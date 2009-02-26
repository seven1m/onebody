class Administration::LogosController < ApplicationController
  before_filter :only_admins
  
  def show
    @filename = Setting.get(:appearance, :logo)
  end
  
  def create
    unless params[:file].to_s.blank?
      if img = MiniMagick::Image.from_blob(params[:file].read) rescue nil \
      and ending = {'JPEG' => 'jpg', 'GIF' => 'gif', 'PNG' => 'png'}[img['format']]
        filename = "logo#{Site.current.id}.#{ending}"
        img.thumbnail('400x80') if img['width'] > 400 or img['height'] > 80
        path = "#{Rails.root}/public/images/#{filename}"
        img.write(path)
        File.chmod(0664, path)
        Setting.set(Site.current.id, 'Appearance', 'Logo', filename)
      end
    end
    redirect_to administration_logo_path
  end
  
  def destroy
    if Setting.get(:appearance, :logo).to_s.any?
      filename = "#{Rails.root}/public/images/#{Setting.get(:appearance, :logo)}"
      File.delete(filename) if File.exist?(filename)
      Setting.set(Site.current.id, 'Appearance', 'Logo', nil)
    end
    redirect_to administration_logo_path
  end
  
end
