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

  def breadcrumbs
    content_tag(:ol, class: 'breadcrumb') do
      crumbs.map do |icon_class, label, path|
        content = (content_tag(:i, '', class: icon_class) + ' ' + h(label)).html_safe
        content_tag(:li, class: path ? '' : 'active') do
          if path
            link_to content, path
          else
            content
          end
        end
      end.join.html_safe
    end
  end

  def crumbs
    [].tap do |crumbs|
      crumbs << ['fa fa-home', t('nav.home'), root_path]
      if params[:controller] == 'people' and params[:action] == 'show' and params[:business]
        crumbs << ['fa fa-archive', t('nav.directory_sub.business'), search_path(business: true)]
        crumbs << ['fa fa-briefcase', t('nav.business_profile')]
      elsif params[:controller] == 'people' and @person
        crumbs << ['fa fa-archive', t('nav.directory'), search_path]
        crumbs << ['fa fa-user', t('nav.profile')]
      elsif params[:controller] == 'pages'
        crumbs << ['fa fa-gear', t('nav.admin'), admin_path]
      elsif %w(searches printable_directories).include?(params[:controller])
        crumbs << ['fa fa-archive', t('nav.directory'), search_path]
      elsif params[:controller] == 'news' and params[:action] != 'index'
        crumbs << ['fa fa-bullhorn', t('news.heading'), news_path]
      elsif params[:controller] == 'verses' and params[:action] != 'index'
        crumbs << ['fa fa-book', t('verses.heading'), verses_path]
      elsif params[:controller] == 'groups' and params[:action] != 'index'
        crumbs << ['fa fa-group', t('groups.heading'), groups_path]
      end
    end
  end

  def tab_selected
    case params[:controller]
    when 'streams'
      :home
    when *%w(people accounts privacies relationships)
      :profile if @person.try(:persisted?) and (me? or @logged_in.can_edit?(@person))
    when 'groups'
      :groups
    when *%w(searches printable_directories)
      :directory
    when /^administration\//
      :admin
    end
  end

  def tab_selected?(tab)
    tab_selected == tab
  end

  NEW_GROUP_AGE = 5.days

  def new_group_badge
    count = if @logged_in.admin?(:manage_groups)
      Group.recent(NEW_GROUP_AGE).count
    else
      Group.is_public.recent(NEW_GROUP_AGE).count
    end
    if count > 0
      content_tag(:small, class: 'badge bg-green') do
        t('nav.groups_sub.new_count', count: count)
      end
    end
  end

end
