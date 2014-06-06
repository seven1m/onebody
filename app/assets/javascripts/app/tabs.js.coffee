if location.hash.match(/^#tab-/)
  $(".nav-tabs a[href=##{location.hash.replace('#tab-', '')}]").tab('show')

$('a[data-toggle="tab"]').on 'shown.bs.tab', (e) ->
  window.location.hash = e.target.hash.replace('#', '#tab-')

if errored_pane = $('.tab-pane .field_with_errors:eq(1)').parents('.tab-pane').attr('id')
  $(".nav-tabs a[href=##{errored_pane}]").tab('show')
