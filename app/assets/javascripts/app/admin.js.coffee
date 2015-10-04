for section in $('.collapsable-heading')
  section = $(section)
  if section.find('.box, .small-box').length == 0
    section.find('h2').hide()

$('#site-colors > label').hover (e) ->
  skin = $(this).find("input").val()
  $(document.body).removeClass (index,css) ->
    return (css.match(/\bskin-\S+/g) || []).join(' ')
  $(document.body).addClass(skin)

$('#site-colors > label').click (e) ->
  skin = $(this).find("input").val()
  $(document.body).removeClass (index,css) ->
    return (css.match(/\bskin-\S+/g) || []).join(' ')
  $(document.body).addClass(skin)

$('#site-shades > label').hover (e) ->
  shade = if $(this).find("input").val() == 'light' then '-light' else ''
  skin = $(document.body).attr('class').match(/skin-[^- ]+/)
  color = $(document.body).attr('class').match(/skin-[^- ]+/)
  $(document.body).removeClass (index,css) ->
    return (css.match(/\bskin-\S+/g) || []).join(' ')
  $(document.body).addClass(skin + shade)
