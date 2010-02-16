class PagesController < ApplicationController
  skip_before_filter :authenticate_user, :only => %w(show_for_public)
  skip_before_filter :feature_enabled?
  before_filter :get_path
  before_filter :get_page, :get_user, :only => %w(show_for_public)
  before_filter :feature_enabled?, :only => %w(show_for_public) # must follow get_page
  
  #caches_action :show_for_public, :for => 1.day,
  #  :cache_path => Proc.new { |c| "pages/#{c.instance_eval('@page.path')}" rescue '' },
  #  :if => Proc.new { |c| !(l = c.instance_eval('@logged_in')) or !l.admin?(:edit_pages) }
  #cache_sweeper :page_sweeper, :only => %w(create update destroy)
  
  def index
    if @parent = Page.find_by_id(params[:parent_id])
      @pages = @parent.children.all(:order => 'title')
    else
      @pages = Page.find_all_by_parent_id(nil)
    end
  end
  
  def show_for_public
    if @theme_name == 'page:template'
      if @page.published?
        render_with_template(@page)
      else
        render_with_template(I18n.t('pages.not_found'), 404)
      end
    else
      if @page
        if @page.published?
          if @page.path =~ /\/tour_/
            render :action => 'tour_show', :layout => false
          else
            render :action => 'show'
          end
        else
          render :text => I18n.t('pages.not_found'), :status => 404
        end
      elsif is_tour_page?
        render :file => RAILS_ROOT + "/public/#{@path}.html.liquid"
      else
        render :text => I18n.t('pages.not_found'), :status => 404
      end
    end
  end
  
  def show
    @page = Page.find(params[:id])
    unless @logged_in.admin?(:edit_pages)
      redirect_to page_for_public_path(:path => @page.path)
    end
  end
  
  def new
    if @logged_in.admin?(:edit_pages)
      @page = Page.new(:parent_id => params[:parent_id])
      @page_paths_and_ids = Page.paths_and_ids
    else
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
  def create
    if @logged_in.admin?(:edit_pages)
      @page = Page.create(params[:page])
      unless @page.errors.any?
        flash[:notice] = I18n.t('pages.saved')
        redirect_to params[:commit] =~ /continue editing/i ? edit_page_path(@page) : @page
      else
        @page_paths_and_ids = Page.paths_and_ids
        render :action => 'new'
      end
    else
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
  def edit
    @page = Page.find(params[:id])
    if @logged_in.can_edit?(@page)
      @page_paths_and_ids = Page.paths_and_ids
    else
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
  def update
    @page = Page.find(params[:id])
    if @logged_in.can_edit?(@page)
      if @page.update_attributes(params[:page])
        flash[:notice] = I18n.t('pages.saved')
        redirect_to params[:commit] =~ /continue editing/i ? edit_page_path(@page) : @page
      else
        @page_paths_and_ids = Page.paths_and_ids
        render :action => 'edit'
      end
    else
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
  def destroy
    @page = Page.find(params[:id])
    if @logged_in.can_edit?(@page)
      @page.destroy
      if @page.errors.any?
        add_errors_to_flash(@page)
      else
        flash[:notice] = I18n.t('pages.deleted')
      end
      redirect_to pages_path
    else
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
  private
  
    def render_with_template(page, status=200)
      content = page.is_a?(String) ? page : page.body
      if template = Page.find_by_path('template')
        render :text => template.body.sub(/\[\[content\]\]/, content), :status => status
      else
        render :text => I18n.t('pages.template_not_found'), :layout => true, :status => 500
      end
    end
  
    def get_path
      @path = [*params[:path]].join('/')
      if @path.sub!(%r{/edit$}, '')
        redirect_to edit_page_path(Page.find(@path))
        return false
      end
    end
    
    def get_page
      @page = Page.find_by_id_or_path(@path)
    end
    
    def get_theme_name
      if params[:action] == 'show_for_public'
        if (@theme_name = Setting.get(:appearance, :public_theme)) == 'page:template'
          'aqueouslight'
        else
          @theme_name
        end
      else
        super
      end
    end
    
    def is_tour_page?
      @path =~ /^help\/tour_[a-z]+$/ and File.exist?("#{Rails.root}/public/#{@path}.html.liquid")
    end
    
    def feature_enabled?
      unless (@page and @page.system? and !@page.home?) or \
        is_tour_page? or Setting.get(:features, :content_management_system)
        redirect_to stream_path
        false
      end
    end

end
