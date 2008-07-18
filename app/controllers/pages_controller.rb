class PagesController < ApplicationController
  skip_before_filter :authenticate_user, :only => %w(show_for_public)
  before_filter :get_path
  before_filter :get_page, :only => %w(show_for_public)
  
  #caches_action :show_for_public, :for => 1.day, :cache_path => Proc.new { |c| "pages/#{c.instance_eval('@page.path')}" rescue '' }
  cache_sweeper :page_sweeper, :only => %w(create update destroy)
  
  def index
    @pages = Page.find_all_by_parent_id(params[:parent_id], :order => 'title')
    @parent = Page.find_by_id(params[:parent_id])
  end
  
  def show_for_public
    if @page.published?
      render :action => 'show'
    else
      render :text => 'Page not found.', :status => 404
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
        redirect_to @page
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
        redirect_to @page
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
      flash[:notice] = 'Page deleted.'
      redirect_to pages_path
    else
      render :text => 'You are not authorized to delete this page.', :layout => true, :status => 401
    end
  end
  
  private
  
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
        Setting.get(:appearance, :public_theme)
      else
        super
      end
    end

end
