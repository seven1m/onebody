$(document).on 'click', '.timeline-load-more a', (e) ->
  e.preventDefault()
  button = $(this)
  loading = new Spinner({radius: 5, length: 5, width: 2}).spin(button.parent()[0])
  timeline = button.parent().siblings('ul.timeline')
  $.getJSON timeline.data('next-url'), (data) ->
    loading.stop()
    if data.items.length > 0
      html = $.parseHTML(data.html)[0].innerHTML
      timeline.append(html).data('next-url', data.next)
    if data.items.length == 0 or data.next == null
      button.hide()
