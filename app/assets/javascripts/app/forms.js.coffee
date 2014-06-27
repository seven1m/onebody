$('.field_with_errors label').each ->
  $(this).parents('.form-group').addClass('has-error')
    .find('label').prepend("<i class='fa fa-times-circle-o'></i> ")
$('.form-errors li').each ->
  id = $(this).data('attribute')
  if $('#' + id).length > 0
    button = $("<a href='#' class='btn btn-xs bg-gray text-red'><i class='fa fa-hand-o-down'></i></a>")
    $(this).append(' ')
    $(this).append(button)
    button.click (e) ->
      e.preventDefault()
      group = $("##{id}").parents('.form-group')
      $.scrollTo(group, duration: 800, easing: 'swing')
