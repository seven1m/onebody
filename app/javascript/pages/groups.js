$(document).on('change', '.group-category-lookup select', function() {
  const category = $(this).val()
  if (category !== '') {
    location.href = `?category=${category}`
  }
})

$(document).on('change', '#group_private', function() {
  if ($(this).is(':checked')) {
    $('#group_approval_required_to_join').prop('checked', true)
  }
})

const mode = $('select#group_membership_mode')
mode.change(() => {
  $('.membership-mode-option').hide()
  $('#' + mode.val()).show()
})
mode.trigger('change')

const update_group_address = (name) => {
  const val = name.replace(/[^a-z0-9-]+/g, '')
  $('#group_address').val(val)
}

$(document).on('keyup', '#group_name', function() {
  const name = $(this).val()
  update_group_address(name)
})

$(document).on('keyup', '#group_address', function() {
  const name = $(this).val()
  update_group_address(name)
})
