const datepicker_format = $('body').data('datepicker-format')
window.date_pickers = {}
const date_options = {
  format: datepicker_format,
  onRender: () => ''
}

$('.date-picker-btn').click((e) => {
  const input = $(e.target).parents('.form-group').find('input')
  const id = input.prop('id')
  let picker = date_pickers[id]
  if (picker) {
    picker.hide()
    delete date_pickers[id]
  } else {
    picker = new $.fn.datepicker.Constructor(input[0], date_options)
    picker.show()
    // hide other date pickers
    Object.keys(date_pickers).forEach((i) => {
      let p = date_pickers[i]
      p.hide()
      delete date_pickers[i]
    })
    date_pickers[id] = picker
  }
})
