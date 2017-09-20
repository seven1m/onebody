const nav = function() {
  addOrUpdateURLParam('attended_at', encodeURIComponent(this.value))
}

$('#attended_at').on('changeDate', nav).on('change', nav)

$('body').on('click', '.attendance input#order', function() {
  let order
  if ($(this).is(':checked')) {
    order = 'last'
  } else {
    order = 'first'
  }
  addOrUpdateURLParam('order', order)
})
