class StreamItemDecorator < Draper::Decorator
  MAX_BODY_SIZE = 250
  MAX_PICTURES = 10

  delegate_all

  def publishable?
    shared? && !(streamable_type == 'Message' && group_id.nil?)
  end

  def to_html(options = {})
    return unless publishable?
    h.content_tag(:li) do
      if streamable_type == 'StreamItemGroup'
        group_content
      else
        icon +
        h.content_tag(:div, class: 'timeline-item') do
          h.content_tag(:span, class: 'time') do
            h.icon('fa fa-clock-o') + ' ' + created_at.to_s(:time) +
              (new? ? new_badge : '')
          end +
          header +
          body +
          footer
        end
      end
    end.html_safe
  end

  def group_content
    url = h.stream_url(format: :json, stream_item_group_id: id)
    h.content_tag(:div, class: 'timeline-item') do
      h.content_tag(:div, class: "timeline-body #{streamable_css_class}") do
        I18n.t(
          "#{object.context.fetch(:streamable_type, '').underscore}.description",
          scope: 'stream.body.stream_item_group',
          count: items.count,
          default: ''
        ).html_safe +
        footer(class: 'timeline-group-load-more', data: { 'group-url' => url })
      end
    end
  end

  def icon
    case streamable_type
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
        who = h.content_tag(:div, class: 'user-header') do
          h.concat(h.image_tag(h.avatar_path(person), {class: 'avatar tn img-circle'}).html_safe)
          h.concat(h.link_to(person.name, person))
        end
      else
        who = I18n.t('stream.header.noone')
      end
      case streamable_type
      when 'Album'
        args = {
          who: who,
          count: Array(object.context['picture_ids']).length,
          album: h.link_to(title, h.album_path(streamable_id))
        }
        if streamable.group
          I18n.t(
            'stream.header.picture_in_group',
            args.merge(
              group: h.link_to(streamable.group.name, streamable.group)
            )
          ).html_safe
        else
          I18n.t('stream.header.picture', args).html_safe
        end
      when 'Verse'
        I18n.t('stream.header.verse', who: who, title: h.link_to(title, path)).html_safe
      when 'NewsItem'
        I18n.t('stream.header.news', who: who, title: h.link_to(title, path)).html_safe
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
    h.content_tag(:div, class: "timeline-body #{streamable_css_class}") do
      if streamable_type == 'Message'
        h.truncate_html(h.render_message_body(object), length: MAX_BODY_SIZE)
      elsif streamable_type == 'Person' && streamable
        h.link_to streamable, class: 'btn btn-info' do
          I18n.t('stream.body.person.button', person: streamable.name)
        end
      elsif streamable_type == 'PrayerRequest' && streamable
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
        pics = Array(object.context['picture_ids'])
        pics = pics[-MAX_PICTURES..-1] if pics.length > MAX_PICTURES
        pics.map do |picture_id, fingerprint, extension|
          url = Picture.photo_url_from_parts(picture_id, fingerprint, extension, :small)
          h.link_to(
            h.image_tag(url, alt: I18n.t('stream.body.picture.alt'), class: 'timeline-pic small'),
            h.album_picture_path(streamable_id, picture_id),
            title: I18n.t('stream.body.picture.alt')
          )
        end.join(' ').html_safe
      elsif streamable_type == 'Site'
        I18n.t('stream.body.site.description', site: Setting.get(:name, :community))
      end
    end
  end

  def footer(options = {})
    label = I18n.t(
      streamable_type.underscore,
      scope: 'stream.footer.button_label',
      default: I18n.t('stream.footer.button_label.default')
    )
    return if label.blank?
    h.content_tag(:div, class: 'timeline-footer') do
      h.link_to(
        label,
        path,
        class: "btn btn-primary btn-xs #{options[:class]}",
        data: options[:data]
      )
    end
  end

  def path
    case streamable_type
    when 'Album', 'Message', 'Person', 'Verse', 'NewsItem'
      h.send(streamable_type.underscore + '_path', streamable_id)
    when 'Site'
      ''
    else
      streamable
    end
  end

  def streamable_css_class
    "streamable-#{streamable_type.underscore.dasherize}"
  end

  def new?
    return false unless h.current_user.last_seen_stream_item
    created_at > h.current_user.last_seen_stream_item.created_at
  end

  def new_badge
    h.content_tag(:small, h.t('new'), class: 'badge bg-green')
  end
end
