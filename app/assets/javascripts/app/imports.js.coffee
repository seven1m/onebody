$(document).on 'change, ifToggled', '#import_dont_preview', (e) ->
  $('#btn-execute').toggle(@checked)
  $('#btn-preview').toggle(!@checked)
