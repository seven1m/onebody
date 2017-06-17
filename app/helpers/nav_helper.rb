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
      tab_link(t('nav.home'), stream_path, params[:controller] == 'streams', 'home-tab')
    end
  end

  def profile_nav_link
    path = @logged_in ? person_path(@logged_in) : people_path
    content_tag(:li) do
      tab_link(t('nav.profile'), path, params[:controller] == 'people' && me?, 'profile-tab')
    end
  end

  def groups_nav_link
    content_tag(:li) do
      tab_link(t('nav.groups'), groups_path, params[:controller] == 'groups', 'group-tab')
    end
  end

  def directory_nav_link
    content_tag(:li) do
      tab_link(t('nav.directory'), new_search_path, %w(searches printable_directories).include?(params[:controller]), 'directory-tab')
    end
  end

  def common_nav_links
    [].tap do |links|
      if @logged_in
        links << content_tag(:li, link_to(t('admin.admin'), admin_path)) if @logged_in.admin?
        links << content_tag(:li, link_to(t('session.sign_out'), session_path, method: :delete))
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
    BreadcrumbPresenter.new(params, assigns).crumbs
  end

  def tab_selected
    case params[:controller]
    when 'streams'
      :home
    when 'people', 'accounts', 'privacies', 'relationships'
      :profile if @person.try(:persisted?) && (me? || @logged_in.can_update?(@person))
    when 'groups', 'tasks'
      :groups
    when 'searches', 'printable_directories'
      :directory
    when /^administration\//
      :admin
    end
  end

  def tab_selected?(tab)
    tab_selected == tab
  end

  def tab_expanded
    if tab_selected?(:groups)
      :groups if @group && @logged_in.can_update?(@group)
    else
      tab_selected
    end
  end

  def tab_expanded?(tab)
    tab_expanded == tab
  end

  def new_stream_activity_badge(person)
    if (count = new_stream_activity(person)) > 0
      content_tag(:small, class: 'badge bg-green') do
        t('nav.home_sub.new_count', count: count)
      end
    end
  end

  def new_group_badge
    if (count = new_groups.count) > 0
      content_tag(:small, class: 'badge bg-green') do
        t('nav.groups_sub.new_count', count: count)
      end
    end
  end

  def assigned_tasks_badge
    if (count = @logged_in.incomplete_tasks_count) > 0
      content_tag(:small, class: 'badge bg-green') do
        t('nav.tasks_sub.assigned_count', count: count)
      end
    end
  end
end
