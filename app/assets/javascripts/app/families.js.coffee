$('.family-name-suggestion-button').click (e) ->
  e.preventDefault()
  $(this).parents('.form-group').find('.form-control').val(
    $(this).data('name')
  )
