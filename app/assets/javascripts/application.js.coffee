#= require jquery
#= require jquery_ujs
#= require bootstrap
#= require admin_lte
#= require spin

$(document).on 'click', '.timeline-load-more a', (e) ->
  e.preventDefault()
  button = $(this)
  loading = new Spinner({radius: 5, length: 5, width: 2}).spin(button.parent()[0])
  timeline = button.parent().siblings('ul.timeline')
  $.getJSON timeline.data('next-url'), (data) ->
    loading.stop()
    html = $.parseHTML(data.html)[0].innerHTML
    timeline.append(html).data('next-url', data.next)
