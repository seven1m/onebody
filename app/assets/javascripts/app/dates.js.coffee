i = document.createElement('input')
i.setAttribute('type', 'date')
window.DATE_INPUT_SUPPORTED = i.type != 'text'

unless DATE_INPUT_SUPPORTED
  datepicker_format = $('body').data('datepicker-format')
  timeouts = {}
  $('input[type=date]').datepicker(format: datepicker_format).focus (e) ->
    $('input[type=date]').each ->
      $(this).datepicker('hide') unless this == e.target
