class BreadcrumbPresenter
  def initialize(params, assigns)
    @params = params
    (@controller, @action) = @params.values_at(:controller, :action)
    @route = @controller + '#' + @action
    @assigns = assigns
    @crumbs = []
    @debug = false
    generate!
  end

  attr_accessor :crumbs

  def generate!
    crumbs << ['fa fa-home', t('nav.home'), root_path]
    directory_crumb
    family_crumb
    person_crumb
    group_crumb
    album_crumb
    message_crumb
    news_crumb
    verse_crumb
    prayer_request_crumb
    admin_crumb
    document_crumb
    task_crumb
    reports_crumb
    imports_crumb
  end

  private

  def directory_crumb
    if (@controller == 'people' && @action != 'import') || @controller == 'families'
      crumbs << if @params[:business]
                  ['fa fa-archive', t('nav.directory_sub.business'), search_path(business: true)]
                else
                  ['fa fa-archive', t('nav.directory'), search_path]
                end
    elsif %w(searches printable_directories).include?(@controller) && @action != 'show'
      crumbs << ['fa fa-archive', t('nav.directory'), search_path]
    end
  end

  def family_crumb
    if person && person.family && @route == 'people#show'
      crumbs << ['fa fa-users', person.family.try(:name), family_path(person.family)]
    end
  end

  def person_crumb
    return if (a = @assigns['album']) && a.owner_type == 'Group'
    return if @route == 'groups#index'
    return if @route == 'prayer_requests#show'
    return if @route == 'messages#show' && group
    return if @controller =~ /^administration\//
    if person && @route != 'people#show'
      crumbs << ['fa fa-user', person.name, person_path(person)]
    end
  end

  def person
    @person ||= begin
      p = @assigns['person'] || @assigns.values.detect do |o|
        o.respond_to?(:person) && o.person
      end.try(:person)
      p if p && p.persisted?
    end
  end

  def group_crumb
    return if @controller =~ /^admin/
    if group
      if @route == 'groups#show'
        crumbs << ['fa fa-group', t('nav.groups'), groups_path]
        crumbs << ['fa fa-folder-open', group.category, groups_path(category: group.category)]
      else
        crumbs << ['fa fa-group', group.name, group_path(group)]
      end
    elsif @controller == 'groups' && (@action != 'index' || @params[:name] || @params[:category])
      crumbs << ['fa fa-group', t('nav.groups'), groups_path]
    end
  end

  def group
    @group ||= begin
      g = @assigns['group'] || @assigns.values.detect do |o|
        o.is_a?(ActiveRecord::Base) && o.respond_to?(:group) && o.group && o.group.persisted?
      end.try(:group)
      g if g && g.persisted?
    end
  end

  def album_crumb
    if %w(albums pictures).include?(@controller) && (album = @assigns['album'])
      if album.owner_type == 'Group'
        crumbs << if @route == 'pictures#show'
                    ['fa fa-camera-retro', album.name, group_album_path(album.owner_id, album)]
                  else
                    ['fa fa-camera-retro', t('nav.albums'), group_albums_path(album.owner_id)]
                  end
      elsif album.owner_type == 'Person'
        crumbs << if @route == 'pictures#show'
                    ['fa fa-camera-retro', album.name, person_album_path(album.owner_id, album)]
                  else
                    ['fa fa-camera-retro', t('nav.albums'), person_albums_path(album.owner_id)]
                  end
      end
    end
  end

  def message_crumb
    if @controller == 'messages' && @action != 'index' && group
      crumbs << ['fa fa-envelope', t('nav.messages'), group_messages_path(group)]
    end
  end

  def news_crumb
    if @controller == 'news' && @action != 'index'
      crumbs << ['fa fa-bullhorn', t('nav.news'), news_path]
    end
  end

  def verse_crumb
    if @controller == 'verses' && @action != 'index'
      crumbs << ['fa fa-book', t('nav.verses'), verses_path]
    end
  end

  def prayer_request_crumb
    if @controller == 'prayer_requests' && group
      crumbs << ['fa fa-heart', t('nav.prayer_requests'), group_prayer_requests_path(group)] unless @action == 'index'
    end
  end

  def admin_crumb
    if @controller =~ /^administration\// || @controller == 'pages' || @controller == 'email_setups'
      crumbs << ['fa fa-gear', t('nav.admin'), admin_path]
    end
    if @controller == 'administration/admins' && @assigns['admin']
      crumbs << ['fa fa-gavel', t('nav.admin_sub.admins'), administration_admins_path]
    end
    if @controller == 'pages' && @assigns['page']
      crumbs << ['fa fa-file', t('nav.pages'), pages_path]
    end
    if @controller =~ %r{^administration/checkin/(times|cards|groups|labels)}
      crumbs << ['fa fa-check-square-o', t('nav.checkin'), administration_checkin_dashboard_path]
      if @route == 'administration/checkin/groups#index' && @assigns['time']
        crumbs << ['fa fa-clock-o', t('nav.checkin_sub.times'), administration_checkin_times_path]
      elsif @route =~ %r{administration/checkin/labels#(new|edit)}
        crumbs << ['fa fa-tags', t('nav.checkin_sub.labels'), administration_checkin_labels_path]
      end
    end
  end

  def document_crumb
    if @controller == 'documents'
      if folder = @assigns['document'] || @assigns['parent_folder'] || @assigns['folder']
        folders = []
        while folder = folder.folder
          folders.unshift([
                            folders.empty? ? 'fa fa-folder-open-o' : 'fa fa-folder-o',
                            folder.name,
                            documents_path(folder_id: folder)
                          ])
        end
        @crumbs << ['fa fa-files-o', 'Documents', documents_path]
        @crumbs += folders
      end
    end
  end

  def task_crumb
    if @controller == 'tasks' && group
      crumbs << ['fa fa-check-square', t('nav.tasks'), group_tasks_path(group)] unless @action == 'index'
    end
  end

  def reports_crumb
    if @controller == 'reports' || @controller == 'custom_reports'
      crumbs << ['fa fa-gear', t('nav.admin'), admin_path]
      crumbs << ['fa fa-table', t('nav.report'), admin_reports_path]
    end
  end

  def imports_crumb
    if @controller == 'administration/imports'
      crumbs << ['fa fa-upload', t('nav.imports'), administration_imports_path]
    end
  end

  def t(*args)
    I18n.t(*args)
  end

  def method_missing(method, *args)
    Rails.application.routes.url_helpers.send(method, *args)
  end
end
