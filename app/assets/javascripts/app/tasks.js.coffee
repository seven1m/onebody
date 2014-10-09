$(document).on 'change, ifToggled', '.complete-task-form input', (event) ->
  form = $(this).closest('form')
  $(this).closest('li.task').toggleClass('done')
  $.post form.attr('action'), form.serialize()
