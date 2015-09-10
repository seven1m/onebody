$(document).on 'change', '.group-category-lookup select', (e) ->
  category = $(this).val()
  location.href = '?category=' + category unless category == ''

$(document).on 'change', '#group_private', (e) ->
  if $(this).is(':checked')
    $('#group_approval_required_to_join').attr('checked', true)

$(document).on 'keyup', '#group_address', (e) ->
  val = $(this).val().replace(/[^a-z0-9\-]+/, '')
  $(this).val(val)

mode = $('select#group_membership_mode')
mode.change ->
  $('.membership-mode-option').hide()
  $('#' + mode.val()).show()
mode.trigger('change')
