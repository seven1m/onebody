hiding = null

$('.list-checkin-status button').hide()
$('.list-checkin').find('input[type="checkbox"]').change ->
  form = $('.list-checkin').parents('form')
  url = form.attr('action') + '.json'
  data = form.serialize()
  clearTimeout(hiding) if hiding
  status = $('.list-checkin-status .status').html(
    "<i class='fa fa-spinner fa-spin'></i>"
  ).show()
  $.ajax
    method: 'POST'
    url: url
    data: data
    success: (resp) ->
      if resp?.status == 'ok'
        message = "<i class='fa fa-check-circle text-green'></i>"
      else
        message = "<i class='fa fa-exclamation-triangle text-red'></i>"
      message += ' ' + (resp?.message || '')
      status.html(message)
      hiding = setTimeout (-> status.hide()), 3000
    error: (_xhr, err) ->
      message = "<i class='fa fa-exclamation-triangle text-red'></i> " + err
      status.html(message)

$('#attendance_form #notes').on 'input', ->
  $('.list-checkin-status button').show()
