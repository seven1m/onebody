$(document).on 'change, ifToggled', '.complete-task-form input', (event) ->
  form = $(this).closest('form')
  $(this).closest('li.task').toggleClass('done')
  $.post form.attr('action'), form.serialize()

todolist = $('ul.todo-list')

todolist.sortable
  handle: '.handle'

todolist.on 'sortupdate', (event, ui) ->
  task = $(ui.item)
  position = task.parent().children().index(ui.item)

  console.log(task.data("id"))
  $.post '/tasks/'+task.data("id")+'/update_position', {position: position+1}
  console.log(ui.item)
  console.log(position)