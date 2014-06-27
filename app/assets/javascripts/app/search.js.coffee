$(document).on 'change, ifToggled', '#enable-advanced-search', (e) -> # use the 'ifToggled' event to work with iCheck plugin
  checked = $(this).is(':checked')
  $('.advanced-controls').toggle(checked)
  if not checked
    $('.advanced-controls').find('input, select').val('')

$('#enable-advanced-search').trigger('change').trigger('ifToggled')
