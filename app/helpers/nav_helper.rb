module NavHelper

  def nav_links
    [].tap do |links|
      links << home_nav_link
      links << profile_nav_link
      links << groups_nav_link if Setting.get(:features, :groups)
      links << directory_nav_link
    end.join.html_safe
  end

  def home_nav_link
    content_tag(:li) do
      tab_link(t("nav.home"), stream_path, params[:controller] == 'streams', 'home-tab')
    end
  end

  def profile_nav_link
    path = @logged_in ? person_path(@logged_in) : people_path
    content_tag(:li) do
      tab_link(t("nav.profile"), path, params[:controller] == 'people' && me?, 'profile-tab')
    end
  end

  def groups_nav_link
    content_tag(:li) do
      tab_link(t("nav.groups"), groups_path, params[:controller] == 'groups', 'group-tab')
    end
  end

  def directory_nav_link
     content_tag(:li) do
      tab_link(t("nav.directory"), new_search_path, %w(searches printable_directories).include?(params[:controller]), 'directory-tab')
    end
  end

  def common_nav_links
    [].tap do |links|
      if @logged_in
        links << content_tag(:li, link_to(t("admin.admin"), admin_path)) if @logged_in.admin?
        links << content_tag(:li, link_to(t("session.sign_out"), session_path, method: :delete))
      end
    end.join.html_safe
  end

end
