$('input.icon-check[type="checkbox"]').each ->
  elm = $(this)
  icon = $('<i>', class: 'fa fa-fw clickable')
  icon.insertAfter(elm)
  change = ->
    if elm.is(':checked')
      icon.removeClass('fa-square-o').addClass('fa-check-square')
    else
      icon.addClass('fa-square-o').removeClass('fa-check-square')
  elm.hide().change(change)
  icon.click ->
    elm.prop('checked', !elm.is(':checked'))
    elm.trigger('change')
  change()
