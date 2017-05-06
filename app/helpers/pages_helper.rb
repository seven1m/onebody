module PagesHelper
  def render_page_content(path)
    page = Page.where(path: path, published: true).first
    return unless page
    sanitize_html(page.body)
  end

  def help_path(name = nil)
    page_for_public_path("help/#{name}")
  end
end
