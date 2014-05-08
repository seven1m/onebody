module PagesHelper

  def breadcrumbs_for(page)
    if parent = page.parent and not parent.system?
      link_to(parent.title, page_path(parent)) + sanitize(' &raquo;')
    end
  end

  def home_path
    if @logged_in and @logged_in.admin?(:edit_pages)
      page_path(Page.where(path: "home").first)
    else
      root_path
    end
  end

end
