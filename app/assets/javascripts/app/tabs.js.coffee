show_tab = ->
  if location.hash.match(/^#tab-/)
    $(".wrapper .nav-tabs a[href='##{location.hash.replace('#tab-', '')}']").tab('show')

show_default_tab = ->
  if $('.wrapper .nav-tabs').length > 0
    default_hash = $('.wrapper .nav-tabs .active a')[0].hash.replace('#', '')
    window.history.replaceState({}, '', ("#tab-" + default_hash))

show_tab() || show_default_tab()

$(window).on 'popstate', show_tab

$('a[data-toggle="tab"]').on 'shown.bs.tab', (e) ->
  window.location.hash = e.target.hash.replace('#', '#tab-')

if errored_pane = $('.tab-pane .field_with_errors:eq(1)').parents('.tab-pane').attr('id')
  $(".wrapper .nav-tabs a[href=##{errored_pane}]").tab('show')
