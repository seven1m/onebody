$('#family_visible').change ->
  if @checked
    $('.people-header-row, .person-row').show()
  else
    $('.people-header-row, .person-row, .membership-row').hide()

$('#family_visible').trigger('change')

$('.visible-checkbox').change ->
  c = $(this).closest('tr').find('input[type=checkbox]:not(.visible-checkbox)')
  if @checked
    c.prop('disabled', false).each ->
      c = $(this).data('was-checked')
      @checked = c  if c?
  else
    c.prop('disabled', true).each(->
      $(this).data('was-checked', @checked)
    ).prop('checked', false)

$('.visible-checkbox').trigger('change')

$('.share-checkbox').change (event, triggered) ->
  id = $(this).data('person-id')
  type = $(this).data('share-type')
  c = $('.membership-for-' + id + ' .' + type)
  if @checked
    c.prop('checked', true).prop('disabled', true)
  else
    c.prop('disabled', false)
    c.prop('checked', false) unless triggered

$('.share-checkbox').trigger('change', 'triggered')

$(document).on 'click', '.expand-link', ->
  $(this).removeClass('fa-plus-circle expand-link').addClass 'fa-minus-circle collapse-link'
  $('.' + $(this).prop('id').replace(/expand\-link\-/, 'membership-for-')).show()

$(document).on 'click', '.collapse-link', ->
  $(this).removeClass('fa-minus-circle collapse-link').addClass 'fa-plus-circle expand-link'
  $('.' + $(this).prop('id').replace(/expand\-link\-/, 'membership-for-')).hide()
