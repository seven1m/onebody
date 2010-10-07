class Administration::ThemesController < ApplicationController

  before_filter :only_admins
  before_filter :get_path

  def show
    redirect_to edit_administration_theme_path
  end

  def edit
    unless File.exist?(@theme_filename)
      File.open(@theme_filename, 'w') { |f| f.write(File.read(@default_theme_filename)) }
      File.chmod(0664, @theme_filename)
    end
    @theme = File.read(@theme_filename)
  end

  def update
    if params[:theme].to_s.strip == ''
      File.delete(@theme_filename)
      redirect_to edit_administration_theme_path
    elsif params[:theme] =~ /<body>.*\{\{\s*content_for_layout\s*\}\}.*<\/body>/m
      File.open(@theme_filename, 'w') { |f| f.write(params[:theme]) }
      File.chmod(0664, @theme_filename)
      expire_fragment(%r{views/people/#{@logged_in.id}_})
      redirect_to edit_administration_theme_path
    else
      render :text => I18n.t('application.custom_theme_message', :content => content_for_layout), :layout => true, :status => 500
    end
  end

  private

  def get_path
    @themes_path = defined?(DEPLOY_THEME_DIR) ? DEPLOY_THEME_DIR : "#{Rails.root}/themes"
    @path = "#{@themes_path}/custom/site#{Site.current.id}/layouts"
    unless File.exist?(@path)
      FileUtils.mkdir_p(@path)
    end
    @theme_filename = @path + '/default.html.liquid'
    @default_theme_filename = "#{Rails.root}/themes/aqueouslight/layouts/default.html.liquid"
  end

end
