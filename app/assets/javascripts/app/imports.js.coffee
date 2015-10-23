$(document).on 'change', '#dont_preview', (e) ->
  $('#btn-execute').toggle(@checked)
  $('#btn-preview').toggle(!@checked)

form = $('#import-form')
input = form.find('.input-group').hide().find('input')
form.find('.browse-button').show().click -> input.trigger('click')
form.find('.submit-group').hide()
input.change -> form.submit()
