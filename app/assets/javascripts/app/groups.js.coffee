$(document).on 'change', '.group-category-lookup select', (e) ->
  category = $(this).val()
  location.href = '?category=' + category unless category == ''

$(document).on 'change, ifToggled', '#group_private', (e) ->
  if $(this).is(':checked')
    $('#group_approval_required_to_join').attr('checked', true).iCheck('check')

$(document).on 'keyup', '#group_address', (e) ->
  val = $(this).val().replace(/[^a-z0-9\-]+/, '')
  $(this).val(val)

$('.membership-mode-option').hide()
mode = $('select#group_membership_mode')
mode.change ->
  $('.membership-mode-option').hide()
  $('#' + mode.val()).show()
  switch mode.val()
    when 'adults'
      $('#group_auto_add').val('adults')
      $('#group_parents_of').val('')
      $('#group_link_code').val('')
    when 'parents_of'
      $('#group_auto_add').val('')
      $('#group_link_code').val('')
    when 'link_code'
      $('#group_auto_add').val('')
      $('#group_parents_of').val('')
    when 'manual'
      $('#group_auto_add').val('')
      $('#group_parents_of').val('')
      $('#group_link_code').val('')
if $('#group_parents_of').val()?.length > 0
  mode.val('parents_of')
if $('#group_link_code').val()?.length > 0
  mode.val('link_code')
if $('#group_auto_add').val() == 'adults'
  mode.val('adults')
mode.trigger('change')
