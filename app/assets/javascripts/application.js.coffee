#= require jquery
#= require jquery_ujs
#= require jquery.scrollTo
#= require bootstrap
#= require admin_lte
#= require spin

# # # timeline # # #

$(document).on 'click', '.timeline-load-more a', (e) ->
  e.preventDefault()
  button = $(this)
  loading = new Spinner({radius: 5, length: 5, width: 2}).spin(button.parent()[0])
  timeline = button.parent().siblings('ul.timeline')
  $.getJSON timeline.data('next-url'), (data) ->
    loading.stop()
    if data.items.length > 0
      html = $.parseHTML(data.html)[0].innerHTML
      timeline.append(html).data('next-url', data.next)
    else
      button.hide()

# # # search # # #

# ifToggled for iCheck plugin
$(document).on 'change, ifToggled', '#enable-advanced-search', (e) ->
  checked = $(this).is(':checked')
  $('.advanced-controls').toggle(checked)
  if not checked
    $('.advanced-controls').find('input, select').val('')

$('#enable-advanced-search').trigger('change').trigger('ifToggled')

# # # groups # # #

$(document).on 'change', '.group-category-lookup select', (e) ->
  category = $(this).val()
  location.href = '?category=' + category unless category == ''

# # # photo upload # # #

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

# # # custom select # # #

$(document).on 'change', 'select.can-create', (e) ->
  if $(this).val() == '!'
    val = prompt($(this).data('custom-select-prompt') || 'Please enter a value:')
    if (val || '').length > 0
      $(this).find('option:selected').text(val).attr('value', val)
    else
      $(this).val('')

# # # tabs # # #

if location.hash.match(/^#tab-/)
  $(".nav-tabs a[href=##{location.hash.replace('#tab-', '')}]").tab('show')

$('a[data-toggle="tab"]').on 'shown.bs.tab', (e) ->
  window.location.hash = e.target.hash.replace('#', '#tab-')

if errored_pane = $('.tab-pane .field_with_errors:eq(1)').parents('.tab-pane').attr('id')
  $(".nav-tabs a[href=##{errored_pane}]").tab('show')

# # # families # # #

$('.family-name-suggestion-button').click (e) ->
  e.preventDefault()
  $(this).parents('.form-group').find('.form-control').val(
    $(this).data('name')
  )

# # # forms # # #

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

# # # fire event queue # # #

# these are events that fired before all the js was loaded, now we can catch up...
for e in event_queue
  $(e.target).trigger(e.type)
event_queue.length = 0
