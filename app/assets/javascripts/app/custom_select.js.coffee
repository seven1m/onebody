$(document).on 'change', 'select.can-create', (e) ->
  elm = $(this)
  if elm.val() == '!'
    val = prompt(elm.data('custom-select-prompt') || 'Please enter a value:')
    if (val || '').length > 0
      elm.find('option:selected').text(val).attr('value', val)
    else
      elm.val('')
    elm.trigger('change')
