module PagesHelper

  def breadcrumbs_for(page)
    if page.slug == 'home'
      ''
    elsif parent = page.parent
      link_to(parent.title, page_path(parent)) + ' &raquo;'
    else
      link_to('Home', page_path(Page.find_by_slug('home'))) + ' &raquo;'
    end
  end
  
  
  def page_path(page)
    if @logged_in and @logged_in.admin?(:edit_pages)
      super
    else
      path = page.path == 'home' ? '' : page.path
      page_for_public_path(:path => path)
    end
  end

end
