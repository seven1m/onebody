$(document).on 'change', '.group-category-lookup select', (e) ->
  category = $(this).val()
  location.href = '?category=' + category unless category == ''

$(document).on 'change', '#group_private', (e) ->
  if $(this).is(':checked')
    $('#group_approval_required_to_join').attr('checked', true)

mode = $('select#group_membership_mode')
mode.change ->
  $('.membership-mode-option').hide()
  $('#' + mode.val()).show()
mode.trigger('change')

$(document).on 'keyup', '#group_name', (e) ->
  name = $(this).val()
  update_group_address(name)

$(document).on 'keyup', '#group_address', (e) ->
  name = $(this).val()
  update_group_address(name)

update_group_address = (name) ->
  val = name.replace(/[^a-z0-9\-]+/g, '')
  $('#group_address').val(val)
