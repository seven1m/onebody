showStatusHelp = ->
  status = $('#person_status').val()
  console.log(status)
  $('.status-help').hide()
  $("#status-#{status}").show()

$('#person_status').change(showStatusHelp)

showStatusHelp()
