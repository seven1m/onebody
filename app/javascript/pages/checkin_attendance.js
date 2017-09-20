let hiding

$('.list-checkin-status button').hide()
$('.list-checkin').find('input[type="checkbox"]').change(() => {
  const form = $('.list-checkin').parents('form')
  const url = form.attr('action') + '.json'
  const data = form.serialize()
  if (hiding) clearTimeout(hiding)
  const status = $('.list-checkin-status .status').html(
    "<i class='fa fa-spinner fa-spin'></i>"
  ).show()
  $.ajax({
    method: 'POST',
    url,
    data,
    success: (resp) => {
      let message
      if (resp && resp.status === 'ok') {
        message = "<i class='fa fa-check-circle text-green'></i>"
      } else {
        message = "<i class='fa fa-exclamation-triangle text-red'></i>"
      }
      message += ' ' + (resp && resp.message || '')
      status.html(message)
      hiding = setTimeout(() => status.hide(), 3000)
    },
    error: (_xhr, err) => {
      const message = "<i class='fa fa-exclamation-triangle text-red'></i> " + err
      status.html(message)
    }
  })
})

$('#attendance_form #notes').on('input', () => {
  $('.list-checkin-status button').show()
})
