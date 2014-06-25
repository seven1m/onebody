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
    person_crumb
    group_crumb
    album_crumb
    message_crumb
    news_crumb
    verse_crumb
    prayer_request_crumb
    note_crumb
    admin_crumb
  end

  private

  def directory_crumb
    if @controller == 'people'
      if @params[:business]
        crumbs << ['fa fa-archive', t('nav.directory_sub.business'), search_path(business: true)]
      else
        crumbs << ['fa fa-archive', t('nav.directory'), search_path]
      end
    elsif %w(searches printable_directories).include?(@controller)
      crumbs << ['fa fa-archive', t('nav.directory'), search_path]
    end
  end

  def person_crumb
    return if a = @assigns['album'] and a.owner_type == 'Group'
    return if @route == 'groups#index'
    return if @route == 'prayer_requests#show'
    return if @route == 'messages#show' and group
    if person and @route != 'people#show'
      crumbs << ['fa fa-user', person.name, person_path(person)]
    end
  end

  def person
    @person ||= begin
      p = @assigns['person'] || @assigns.values.detect do |o|
        o.respond_to?(:person) && o.person
      end.try(:person)
      p if p and p.persisted?
    end
  end

  def group_crumb
    if group
      if @route == 'groups#show'
        crumbs << ['fa fa-group', t('groups.heading'), groups_path]
        crumbs << ['fa fa-folder-open', group.category, groups_path(category: group.category)]
      else
        crumbs << ['fa fa-group', group.name, group_path(group)]
      end
    elsif @controller == 'groups' and (@action != 'index' or @params[:name] or @params[:category])
      crumbs << ['fa fa-group', t('groups.heading'), groups_path]
    end
  end

  def group
    @group ||= begin
      g = @assigns['group'] || @assigns.values.detect do |o|
        o.is_a?(ActiveRecord::Base) && o.respond_to?(:group) && o.group && o.group.persisted?
      end.try(:group)
      g if g and g.persisted?
    end
  end

  def album_crumb
    if %w(albums pictures).include?(@controller) and album = @assigns['album']
      if album.owner_type == 'Group'
        if @route == 'pictures#show'
          crumbs << ['fa fa-camera-retro', album.name, group_album_path(album.owner_id, album)]
        else
          crumbs << ['fa fa-camera-retro', t('nav.albums'), group_albums_path(album.owner_id)]
        end
      else
        if @route == 'pictures#show'
          crumbs << ['fa fa-camera-retro', album.name, person_album_path(album.owner_id, album)]
        else
          crumbs << ['fa fa-camera-retro', t('nav.albums'), person_albums_path(album.owner_id)]
        end
      end
    end
  end

  def message_crumb
    if @controller == 'messages' and @action != 'index' and group
      crumbs << ['fa fa-envelope', t('messages.heading'), group_messages_path(group)]
    end
  end

  def news_crumb
    if @controller == 'news' and @action != 'index'
      crumbs << ['fa fa-bullhorn', t('news.heading'), news_path]
    end
  end

  def verse_crumb
    if @controller == 'verses' and @action != 'index'
      crumbs << ['fa fa-book', t('verses.heading'), verses_path]
    end
  end

  def prayer_request_crumb
    if @controller == 'prayer_requests' and group
      crumbs << ['fa fa-heart', t('nav.prayer_requests'), group_prayer_requests_path(group)] unless @action == 'index'
    end
  end

  def note_crumb
    if @assigns['note'] and person
      crumbs << ['fa fa-file', t('nav.notes'), person_notes_path(person)]
    end
  end

  # TODO
  def admin_crumb
    if @controller == 'pages'
      crumbs << ['fa fa-gear', t('nav.admin'), admin_path]
    end
  end

  def t(*args)
    I18n.t(*args)
  end

  def method_missing(method, *args)
    Rails.application.routes.url_helpers.send(method, *args)
  end

end
