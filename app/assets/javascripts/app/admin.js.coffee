for section in $('.collapsable-heading')
  section = $(section)
  if section.find('.box, .small-box').length == 0
    section.find('h2').hide()
