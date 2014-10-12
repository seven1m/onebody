nav = ->
  args = '?attended_at=' + encodeURIComponent(this.value)
  if $('#public').val() == 'true'
    args += '&public=true&token=' + $('#token').val()
  location.href = args
$('#attended_at').on('changeDate', nav).on('change', nav)
