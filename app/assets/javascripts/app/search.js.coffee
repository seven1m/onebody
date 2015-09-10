$(document).on 'change', '#enable-advanced-search', (e) ->
  checked = $(this).is(':checked')
  $('.advanced-controls').toggle(checked)
  if not checked
    $('.advanced-controls').find('input, select').val('')
    $('.advanced-controls').find('#group_select_option').val('1')

$('#enable-advanced-search').trigger('change')
