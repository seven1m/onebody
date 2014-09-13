$(document).on 'change, ifToggled', '.complete-task-form input', (event) ->
  form = $(this).closest('form')
  $(this).closest('li.task').toggleClass('done')
  $.post form.attr('action'), form.serialize()

container = $("ul.todo-list")[0]
if container
  new Sortable(container,
    handle: '.handle'

    onUpdate: (event) ->
      task = $(event.target)
      position = task.parent().children().index(event.target)
      $.post '/tasks/'+task.data("id")+'/update_position', {position: position+1}
  )
