nav = ->
  addOrUpdateURLParam('attended_at', encodeURIComponent(this.value))

$('#attended_at').on('changeDate', nav).on('change', nav)

$('body').on 'click', '.attendance input#order', ->
  order = if $(this).is(':checked') then 'last' else 'first'
  addOrUpdateURLParam('order', order)
