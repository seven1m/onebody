#= require jquery
#= require jquery_ujs
#= require jquery.scrollTo
#= require jquery.color-2.1.2
#= require sortable
#= require bootstrap
#= require bootstrap-datepicker
#= require admin_lte
#= require spin
#= require leaflet
#= require_tree ./app

$('[data-toggle^="#"], [data-toggle^="."]').each (i, elm) ->
  elm = $(elm)
  toggle = (show) -> $(elm.data('toggle')).toggle(show)
  if elm.is(':checkbox')
    enabled_selector = elm.data('toggle-selector') || ':checked'
    elm.on 'change, ifToggled', ->
      toggle(elm.is(enabled_selector))
    toggle(elm.is(enabled_selector))
  else if elm.is('a')
    elm.on('click', toggle)
  else if elm.is('select')
    elm.on 'change', ->
      toggle(elm.val() == elm.data('toggle-value'))
    toggle(elm.val() == elm.data('toggle-value'))
