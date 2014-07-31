$('table.group-times').on 'click', '.btn.up, .btn.down', (e) ->
  e.preventDefault()
  btn = $(e.currentTarget)
  row = btn.parents('tr')
  url = btn.attr('href')
  url += '&full_stop=true' if e.shiftKey
  $.ajax
    url: url
    method: btn.data('method')
    dataType: 'script'
  false
