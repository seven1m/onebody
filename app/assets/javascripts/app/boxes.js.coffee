for box in $('.small-box:not(:has(.small-box-footer))')
  $(box).find('.inner').css('padding-bottom', '35px')

for container in $('.normalize-heights')
  height = 0
  children = $(container).find('.normalize-height')
  for child in children
    h = $(child).height()
    height = h if h > height
  children.css('height', height + 'px')
