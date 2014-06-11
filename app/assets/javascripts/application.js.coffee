#= require jquery
#= require jquery_ujs
#= require jquery.scrollTo
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
    elm.on 'change, ifToggled', (e) ->
      toggle(elm.is(':checked'))
    toggle(elm.is(':checked'))
