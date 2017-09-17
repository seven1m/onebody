$('[data-toggle^="#"], [data-toggle^="."]').each((i, elm) => {
  elm = $(elm)
  const toggle = (show) => $(elm.data('toggle')).toggle(show)
  if (elm.is(':checkbox')) {
    const enabled_selector = elm.data('toggle-selector') || ':checked'
    elm.on('change', () => {
      toggle(elm.is(enabled_selector))
    })
    toggle(elm.is(enabled_selector))
  } else if (elm.is('a')) {
    elm.on('click', () => {
      const elm2 = $(this)
      elm2.toggleClass('expanded')
      toggle(elm2.is('.expanded'))
    })
  } else if (elm.is('select')) {
    elm.on('change', () => {
      toggle(elm.val() == elm.data('toggle-value'))
    })
    toggle(elm.val() == elm.data('toggle-value'))
  }
})
