#= require jquery
#= require jquery_ujs
#= require underscore
#= require react-with-addons
#= require DYMO.Label.Framework
#= require ./pusher_setup
#= require ./app/center
#= require_tree ./app/checkin
#= require_self

if pusher_config?
  if checkin_printer_id
    window.presence_channel = pusher.subscribe('presence-prints')

    updatePrinterStatus = ->
      if presence_channel.members.members[checkin_printer_id]
        status = 'connected'
      else
        status = 'offline'
      checkin.setProps('prints_channel_status': status)

    presence_channel.bind 'pusher:member_added', updatePrinterStatus
    presence_channel.bind 'pusher:member_removed', updatePrinterStatus
    presence_channel.bind 'pusher:subscription_succeeded', updatePrinterStatus

    pusher.connection.bind 'state_change', ({current}) ->
      checkin.setProps('pusher_status': current)
      updatePrinterStatus()

  window.print_label = (data, cb) ->
    if checkin_printer_id
      $.ajax '/checkin/print.json',
        data: JSON.stringify(print: data)
        contentType: 'application/json; charset=utf-8'
        dataType: 'json'
        method: 'post'
        complete: (resp) =>
          data = resp.responseJSON
          if data.error
            cb(data.error)
          else
            cb()
    else
      if new Checkin.LabelSet(data, checkin_labels).print()
        cb()
      else
        cb('error printing')
