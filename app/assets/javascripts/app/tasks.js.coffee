$(document).on 'change, ifToggled', '.complete-task-form input', (event) ->
  form = $(this).closest('form')
  $(this).closest('li.task').toggleClass('done')
  $.post form.attr('action'), form.serialize()

todolist = $('ul.todo-list')

todolist.on 'sortupdate', (event, ui) ->
  task = $(ui.item)
  position = task.parent().children().index(ui.item)
  $.post '/tasks/'+task.data("id")+'/update_position', {position: position+1}