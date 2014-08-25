$('.checkin-groups-table-wrapper').on 'click', '.btn.up, .btn.down', (e) ->
  e.preventDefault()
  e.stopPropagation()
  btn = $(e.currentTarget)
  row = btn.parents('tr')
  url = btn.attr('href')
  url += '&full_stop=true' if e.shiftKey
  if row.is(':not(.expanding)')
    for_folder = row[0].className.match(/for-folder-\d+/)
    up = btn.hasClass('up')
    down = btn.hasClass('down')
    sub = row.hasClass('sub-item')
    first_in_folder = sub and row.prev().is(":not('.#{for_folder[0]}')")
    last_in_folder = sub and (row.next().is(":not('.#{for_folder[0]}')") or row.next().length == 0)
    above_an_expanded_folder = not sub and row.next().is('.expanding.expanded')
    below_an_expanded_folder = not sub and row.prevAll(':not(.sub-item):first').is('.expanding.expanded')
    if down
      if last_in_folder
        url += '&jump_out=true'
      else if above_an_expanded_folder
        url += '&jump_into=' + row.next().attr('id')
    else if up
      if first_in_folder
        url += '&jump_out=true'
      else if below_an_expanded_folder
        url += '&jump_into=' + row.prevAll(':not(.sub-item):first').attr('id')
  $.ajax
    url: url
    method: btn.data('method')
    dataType: 'script'
