$(document).on 'click', 'tr.expanding .folder-link', (e) ->
  e.preventDefault()
  elm = $(this)
  id = elm.data('id')
  tr = elm.closest('tr')
  if tr.hasClass('expanded')
    tr.removeClass('expanded')
    $(".for-folder-#{id}").hide()
  else
    tr.addClass('expanded')
    $(".for-folder-#{id}").show()
