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
      h.icon('fa fa-envelope bg-teal')
    when 'Person'
      h.icon('fa fa-user bg-olive')
    else
      h.icon('fa fa-circle bg-gray')
    end
  end

  def header
    h.content_tag(:h3, class: 'timeline-header') do
      if person
        h.link_to(person.name, person)
      else
        I18n.t('stream.header.noone')
      end +
      ' ' +
      case streamable_type
      when 'Note'
        I18n.t('stream.header.note')
      when 'Album'
        I18n.t('stream.header.picture', count: Array(object.context['picture_ids']).length, album: h.link_to(title, h.album_path(streamable_id))).html_safe
      when 'Verse'
        I18n.t('stream.header.verse', ref: h.link_to(title, path)).html_safe
      when 'NewsItem'
        I18n.t('stream.header.news').html_safe
      when 'Message'
        I18n.t('stream.header.message', group: h.link_to(group.name, group)).html_safe
      when 'Person'
        I18n.t('stream.header.person')
      else
        streamable_type
      end
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
      elsif object.body
        h.truncate_html(h.sanitize_html(h.auto_link(object.body)), length: MAX_BODY_SIZE)
      elsif streamable_type == 'Album'
        Array(object.context['picture_ids']).map do |picture_id, fingerprint, extension|
          url = Picture.photo_url_from_parts(picture_id, fingerprint, extension, @first ? :medium : :small)
          h.link_to(
            h.image_tag(url, alt: I18n.t('stream.body.picture.alt'), class: "timeline-pic #{@first ? 'medium' : 'small'}"),
            h.album_picture_path(streamable_id, picture_id),
            title: I18n.t('stream.body.picture.alt')
          )
        end.join(' ').html_safe
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
    when 'Album', 'Note', 'Message'
      h.send(streamable_type.downcase + '_path', streamable_id)
    else
      streamable # FIXME extra query
    end
  end

    #/ timeline item
    #%li
      #%i.fa.fa-user.bg-aqua
      #.timeline-item
        #%span.time
          #%i.fa.fa-clock-o
          #9:35am
        #%h3.timeline-header.no-border
          #%a{href: "#"} Sarah Young
          #accepted your friend request
    #/ END timeline item
    #/ timeline time label
    #%li.time-label
      #%span.bg-green
        #8 Jan. 2014
    #/ /.timeline-label
    #/ timeline item
    #%li
      #%i.fa.fa-comment.bg-green
      #.timeline-item
        #%span.time
          #%i.fa.fa-clock-o
          #10:21am
        #%h3.timeline-header.no-border
          #%a{href: "#"} Jeremy Zongker
          #posted a note.
        #.timeline-body
          #Bacon ipsum dolor sit amet pork hamburger strip steak jerky landjaeger chuck brisket. Salami doner corned beef rump kevin spare ribs jowl.
        #.timeline-footer
          #%a.btn.btn-primary.btn-xs Read more
          #%a.btn.btn-primary.btn-xs Post a comment
    #/ END timeline item
    #/ timeline item
    #%li
      #%i.fa.fa-check-square-o.bg-yellow
      #.timeline-item
        #%span.time
          #%i.fa.fa-clock-o
          #8:55am
        #%h3.timeline-header.no-border
          #You checked into
          #= succeed "." do
            #%a{href: "#"} The Studio
    #/ END timeline item
    #/ timeline time label
    #%li.time-label
      #%span.bg-green
        #3 Jan. 2014
    #/ /.timeline-label
    #/ timeline item
    #%li
      #%i.fa.fa-camera.bg-purple
      #.timeline-item
        #%span.time
          #%i.fa.fa-clock-o
          #3:09pm
        #%h3.timeline-header
          #%a{href: "#"} Mina Lee
          #uploaded new photos
        #.timeline-body
          #%img.margin{alt: "...", src: "http://placehold.it/150x100"}
          #%img.margin{alt: "...", src: "http://placehold.it/150x100"}
          #%img.margin{alt: "...", src: "http://placehold.it/150x100"}
          #%img.margin{alt: "...", src: "http://placehold.it/150x100"}

  def controller
    params[:controller]
  end

end
