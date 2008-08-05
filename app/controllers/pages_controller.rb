class PagesController < ApplicationController
  skip_before_filter :authenticate_user, :only => %w(show_for_public)
  skip_before_filter :feature_enabled?
  before_filter :get_path
  before_filter :get_page, :get_user, :only => %w(show_for_public)
  before_filter :feature_enabled? # must follow get_page
  
  #caches_action :show_for_public, :for => 1.day,
  #  :cache_path => Proc.new { |c| "pages/#{c.instance_eval('@page.path')}" rescue '' },
  #  :if => Proc.new { |c| !(l = c.instance_eval('@logged_in')) or !l.admin?(:edit_pages) }
  #cache_sweeper :page_sweeper, :only => %w(create update destroy)
  
  def index
    @pages = Page.find_all_by_parent_id(params[:parent_id], :order => 'title')
    @parent = Page.find_by_id(params[:parent_id])
  end
  
  def show_for_public
    if @theme_name == 'page:template'
      if @page.published?
        render_with_template(@page)
      else
        render_with_template('Page not found.', 404)
      end
    else
      if @page.published?
        render :action => 'show'
      else
        render :text => 'Page not found.', :status => 404
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
      render :text => 'You are not authorized to create a page.', :layout => true, :status => 401
    end
  end
  
  def create
    if @logged_in.admin?(:edit_pages)
      @page = Page.create(params[:page])
      unless @page.errors.any?
        flash[:notice] = 'Page saved.'
        redirect_to params[:commit] =~ /continue editing/i ? edit_page_path(@page) : @page
      else
        @page_paths_and_ids = Page.paths_and_ids
        render :action => 'new'
      end
    else
      render :text => 'You are not authorized to create a page.', :layout => true, :status => 401
    end
  end
  
  def edit
    @page = Page.find(params[:id])
    if @logged_in.can_edit?(@page)
      @page_paths_and_ids = Page.paths_and_ids
    else
      render :text => 'You are not authorized to edit this page.', :layout => true, :status => 401
    end
  end
  
  def update
    @page = Page.find(params[:id])
    if @logged_in.can_edit?(@page)
      if @page.update_attributes(params[:page])
        flash[:notice] = 'Page saved.'
        redirect_to params[:commit] =~ /continue editing/i ? edit_page_path(@page) : @page
      else
        @page_paths_and_ids = Page.paths_and_ids
        render :action => 'edit'
      end
    else
      render :text => 'You are not authorized to edit this page.', :layout => true, :status => 401
    end
  end
  
  def destroy
    @page = Page.find(params[:id])
    if @logged_in.can_edit?(@page)
      @page.destroy
      if @page.errors.any?
        add_errors_to_flash(@page)
      else
        flash[:notice] = 'Page deleted.'
      end
      redirect_to pages_path
    else
      render :text => 'You are not authorized to delete this page.', :layout => true, :status => 401
    end
  end
  
  private
  
    def render_with_template(page, status=200)
      content = page.is_a?(String) ? page : page.body
      if template = Page.find_by_path('template')
        render :text => template.body.sub(/\[\[content\]\]/, content), :status => status
      else
        render :text => 'Template not found.', :layout => true, :status => 500
      end
    end
  
    def get_path
      @path = params[:path].to_a.join('/')
      if @path.sub!(%r{/edit$}, '')
        redirect_to edit_page_path(Page.find(@path))
        return false
      end
    end
    
    def get_page
      @page = Page.find(@path)
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
    
    def feature_enabled?
      unless (@page and @page.system? and !@page.home?) or Setting.get(:features, :content_management_system)
        redirect_to people_path
        false
      end
    end

end
