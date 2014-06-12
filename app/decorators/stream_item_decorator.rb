class StreamItemDecorator < Draper::Decorator

  MAX_BODY_SIZE = 250

  # TODO i18n

  delegate_all

  def publishable?
    shared? and not (streamable_type == 'Message' and group_id.nil?)
  end

  def to_html(options={})
    return unless publishable?
    @first = options.delete(:first)
    h.content_tag(:li) do
      icon +
      h.content_tag(:div, class: 'timeline-item') do
        h.content_tag(:span, class: 'time') do
          h.icon('fa fa-clock-o') + ' ' + created_at.to_s(:time)
        end +
        header +
        body +
        footer
      end
    end.html_safe
  end

  def icon
    case streamable_type
    when 'Note'
      h.icon('fa fa-envelope bg-blue')
    when 'Album'
      h.icon('fa fa-camera bg-orange')
    when 'Verse'
      h.icon('fa fa-book bg-green')
    when 'NewsItem'
      h.icon('fa fa-bullhorn bg-red')
    when 'Message'
      h.icon('fa fa-envelope bg-aqua')
    when 'Person'
      h.icon('fa fa-user bg-olive')
    when 'PrayerRequest'
      h.icon('fa fa-heart bg-purple', style: 'line-height:2.2')
    when 'Site'
      h.icon('fa fa-home bg-light-blue')
    else
      h.icon('fa fa-circle bg-gray')
    end
  end

  def header
    h.content_tag(:h3, class: 'timeline-header') do
      if person
        who = h.link_to(person.name, person)
      else
        who = I18n.t('stream.header.noone')
      end
      case streamable_type
      when 'Note'
        I18n.t('stream.header.note', who: who)
      when 'Album'
        args = { who: who, count: Array(object.context['picture_ids']).length, album: h.link_to(title, h.album_path(streamable_id)) }
        if streamable.group
          I18n.t('stream.header.picture_in_group', args.merge(group: h.link_to(streamable.group.name, streamable.group))).html_safe
        else
          I18n.t('stream.header.picture', args).html_safe
        end
      when 'Verse'
        I18n.t('stream.header.verse', who: who, ref: h.link_to(title, path)).html_safe
      when 'NewsItem'
        I18n.t('stream.header.news', who: who).html_safe
      when 'Message'
        I18n.t('stream.header.message', who: who, group: h.link_to(group.name, group)).html_safe
      when 'Person'
        I18n.t('stream.header.person', who: who)
      when 'PrayerRequest'
        I18n.t('stream.header.prayer_request', who: who, group: h.link_to(group.name, group)).html_safe
      when 'Site'
        I18n.t('stream.header.site', who: who, site: Setting.get(:name, :community))
      else
        streamable_type
      end.html_safe
    end.html_safe
  end

  def body
    h.content_tag(:div, class: 'timeline-body') do
      if streamable_type == 'Message'
        h.truncate_html(h.render_message_body(object), length: MAX_BODY_SIZE)
      elsif streamable_type == 'Person' and streamable
        h.link_to streamable, class: 'btn btn-info' do
          I18n.t('stream.body.person.button', person: streamable.name)
        end
      elsif streamable_type == 'PrayerRequest' and streamable
        h.preserve_breaks(object.body).tap do |html|
          if streamable.answer.present?
            html << h.content_tag(:div, class: 'prayer-answer') do
              if streamable.answered_at
                h.content_tag(:h4, I18n.t('prayer_requests.answer.on_date', date: streamable.answered_at.to_s(:date)))
              else
                h.content_tag(:h4, I18n.t('prayer_requests.answer.heading'))
              end +
              h.preserve_breaks(streamable.answer)
            end
          end
        end.html_safe
      elsif object.body
        h.truncate_html(h.sanitize_html(h.auto_link(object.body)), length: MAX_BODY_SIZE)
      elsif streamable_type == 'Album'
        Array(object.context['picture_ids']).map do |picture_id, fingerprint, extension|
          url = Picture.photo_url_from_parts(picture_id, fingerprint, extension, :small)
          h.link_to(
            h.image_tag(url, alt: I18n.t('stream.body.picture.alt'), class: "timeline-pic #{'small'}"),
            h.album_picture_path(streamable_id, picture_id),
            title: I18n.t('stream.body.picture.alt')
          )
        end.join(' ').html_safe
      elsif streamable_type == 'Site'
        I18n.t('stream.body.site.description', site: Setting.get(:name, :community))
      end
    end
  end

  def footer
    h.content_tag(:div, class: 'timeline-footer') do
      label = I18n.t(streamable_type.downcase, scope: 'stream.footer.button_label', default: 'Read more')
      h.link_to label, path, class: 'btn btn-primary btn-xs' if label.present?
    end
  end

  def path
    case streamable_type
    when 'Album', 'Note', 'Message', 'Person', 'Verse', 'NewsItem'
      h.send(streamable_type.underscore + '_path', streamable_id)
    when 'Site'
      ''
    # when 'PrayerRequest'
      # FIXME
    else
      streamable
    end
  end

end
