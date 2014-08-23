$('tr.expanding .folder-link').click (e) ->
  e.preventDefault()
  elm = $(e.delegateTarget)
  id = elm.data('id')
  tr = elm.closest('tr')
  if tr.hasClass('expanded')
    tr.removeClass('expanded')
    $(".for-folder-#{id}").hide()
  else
    tr.addClass('expanded')
    $(".for-folder-#{id}").show()
