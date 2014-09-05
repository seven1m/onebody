$(document).on 'change, ifToggled', '.complete-task-form input', (e) ->
  form = $(this).closest("form")
  $(this).closest("tr.task").toggleClass("completed")
  $.post(form.attr("action"), form.serialize())
