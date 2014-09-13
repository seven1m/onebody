$('.family-name-suggestion-button').click (e) ->
  e.preventDefault()
  $(this).parents('.form-group').find('.form-control').val(
    $(this).data('name')
  )

container = $("table.family tbody")[0];
if container
  new Sortable(container,
    handle: '.handle'
    onUpdate: (event) ->
      person = $(event.target)
      position = person.parent().children().index(event.target)
      path = $('table.family').data('reorder-path')

      $.post path,
        index: position
        person_id: person.data('id')
  )