$(document).on 'change', 'select.can-create', (e) ->
  if $(this).val() == '!'
    val = prompt($(this).data('custom-select-prompt') || 'Please enter a value:')
    if (val || '').length > 0
      $(this).find('option:selected').text(val).attr('value', val)
    else
      $(this).val('')
