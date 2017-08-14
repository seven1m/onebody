#= require jquery
#= require jquery_ujs
#= require jquery.scrollTo
#= require jquery.color-2.1.2
#= require jquery.sparkline
#= require sortable
#= require bootstrap
#= require bootstrap-datepicker
#= require admin_lte
#= require spin
#= require leaflet
#= require leaflet.markercluster
#= require bootstrap-filestyle
#= require_directory ./app
#= require react
#= require react_ujs
#= require react-reorder
#= require components

$('[data-toggle^="#"], [data-toggle^="."]').each (i, elm) ->
  elm = $(elm)
  toggle = (show) -> $(elm.data('toggle')).toggle(show)
  if elm.is(':checkbox')
    enabled_selector = elm.data('toggle-selector') || ':checked'
    elm.on 'change', ->
      toggle(elm.is(enabled_selector))
    toggle(elm.is(enabled_selector))
  else if elm.is('a')
    elm.on 'click', ->
      elm = $(this)
      elm.toggleClass('expanded')
      toggle(elm.is('.expanded'))
  else if elm.is('select')
    elm.on 'change', ->
      toggle(elm.val() == elm.data('toggle-value'))
    toggle(elm.val() == elm.data('toggle-value'))

$(document).on 'click', '[data-select-group] [data-select]', (e) ->
  elm = $(this)
  parent = elm.parents('[data-select-group]')
  [on_class, off_class] = parent.data('select-class').split('/')
  all = parent.find('[data-select]')
  all.removeClass(on_class).addClass(off_class)
  elm.addClass(on_class)
  all_selectors = ($(e).data('select') for e in all)
  selector = elm.data('select')
  $(s).hide() for s in all_selectors
  $(selector).show()

if csrf_token = $('meta[name="csrf-token"]').attr('content')
  $(document).ajaxSend (_, xhr) ->
    xhr.setRequestHeader('X-CSRF-Token', csrf_token)
