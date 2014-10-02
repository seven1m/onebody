container = $(".sortable")[0]
if container
  new Sortable(container,
    handle: '.handle'

    onUpdate: (event) ->
      target = $(event.target)
      index = target.parent().children().index(event.target)
      $.post target.data('update-position-path'), {position: index+1}
  )
