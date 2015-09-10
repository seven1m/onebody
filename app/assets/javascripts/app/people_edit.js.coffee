showStatusHelp = ->
  status = $('#person_status').val()
  $('.status-help').hide()
  $("#status-#{status}").show()

$('#person_status').change(showStatusHelp)

showStatusHelp()
