#= require jquery
#= require jquery_ujs
#= require bootstrap
#= require admin_lte
#= require spin

$(document).on 'click', '.timeline-load-more a', (e) ->
  e.preventDefault()
  button = $(this)
  loading = new Spinner({radius: 5, length: 5, width: 2}).spin(button.parent()[0])
  timeline = button.parent().siblings('ul.timeline')
  $.getJSON timeline.data('next-url'), (data) ->
    loading.stop()
    html = $.parseHTML(data.html)[0].innerHTML
    timeline.append(html).data('next-url', data.next)

# ifToggled for iCheck plugin
$(document).on 'change, ifToggled', '#enable-advanced-search', (e) ->
  checked = $(this).is(':checked')
  $('.advanced-controls').toggle(checked)
  if not checked
    $('.advanced-controls').find('input, select').val('')

$('#enable-advanced-search').trigger('change').trigger('ifToggled')

$(document).on 'change', '.group-category-lookup select', (e) ->
  category = $(this).val()
  location.href = '?category=' + category unless category == ''

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
