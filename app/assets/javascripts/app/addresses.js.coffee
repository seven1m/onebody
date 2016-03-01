$('body').on 'click', '.add-address-button', ->
  blank = $('.blank-address')
  existing = $('.address:not(.blank-address) .address-kind').map(-> $(this).val()).toArray()
  next = _(['home', 'work', 'other']).difference(existing)
  next = 'home' if next.length == 0
  blank
    .clone()
    .removeClass('blank-address')
    .insertBefore(blank)
    .show()
    .find('select.address-kind')
    .val(next)

$('body').on 'click', '.delete-address-button', ->
  address = $(this).parents('.address')
  address.find('.destroy-address-field').val('true')
  address.hide()
