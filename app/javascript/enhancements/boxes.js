$('.small-box:not(:has(.small-box-footer))').each((_i, box) => {
  $(box).find('.inner').css('padding-bottom', '35px')
})

$('.normalize-heights').each((_i, container) => {
  let height = 0
  const children = $(container).find('.normalize-height')
  children.each((_i, child) => {
    const h = $(child).height()
    if (h > height) height = h
  })
  children.css('height', height + 'px')
})
