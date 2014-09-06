datepicker_format = $('body').data('datepicker-format')
date_pickers = {}
date_options =
  format: datepicker_format
  onRender: -> ''

$('.date-picker-btn').click (e) ->
  input = $(e.target).parents('.form-group').find('input')
  id = input.prop('id')
  if (picker = date_pickers[id]) and picker.picker.is(':visible')
    picker.hide()
    delete date_pickers[id]
  else
    picker = new $.fn.datepicker.Constructor(input[0], date_options)
    picker.show()
    for i, picker of date_pickers
      picker.hide()
      delete date_pickers[i]
    date_pickers[id] = picker
