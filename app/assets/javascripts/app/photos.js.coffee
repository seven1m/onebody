$('.photo-upload .file-upload-group').hide()
$('.photo-upload .photo-upload').hide()
$('.photo-upload .photo-browse').show().click (e) ->
  e.preventDefault()
  $(this).parents('.photo-upload').find('input[type="file"]').trigger('click')
$('.photo-upload input[type="file"]').change (e) ->
  form = $(this).parents('form')
  button = form.find('.photo-browse').addClass('disabled').css('position', 'relative')
  new Spinner({radius: 5, length: 5, width: 2}).spin(button[0])
  form.submit()
