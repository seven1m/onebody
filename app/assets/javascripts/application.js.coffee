#= require jquery
#= require jquery_ujs
#= require jquery.scrollTo
#= require jquery.color-2.1.2
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
    elm.on 'change, ifToggled', (e) ->
      toggle(elm.is(enabled_selector))
    toggle(elm.is(enabled_selector))
  if elm.is('a')
    elm.on 'click', ->
      elm = $(this)
      elm.toggleClass('expanded')
      toggle(elm.is('.expanded'))

if csrf_token = $('meta[name="csrf-token"]').attr('content')
  $(document).ajaxSend (_, xhr) ->
    xhr.setRequestHeader('X-CSRF-Token', csrf_token)
