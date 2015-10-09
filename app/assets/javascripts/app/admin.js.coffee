for section in $('.collapsable-heading')
  section = $(section)
  if section.find('.box, .small-box').length == 0
    section.find('h2').hide()

$('div#theme select').first().change (e) ->
  $(document.body).removeClass (index,css) ->
    return (css.match(/\bskin-\S+/g) || []).join(' ')
  skin = $(this).val()
  color = skin.split('-')[1]
  shade = skin.split('-')[2] || 'dark'
  $(document.body).addClass(skin)
  $('#site-colors > label').removeClass('active').filter('.style-'+color).addClass('active')
  $('#site-shades > label').removeClass('active').filter('.style-'+shade).addClass('active')

$('#site-colors > label').hover ((e) ->
  skin = $(this).find("input").val()
  $(document.body).removeClass (index,css) ->
    return (css.match(/\bskin-\S+/g) || []).join(' ')
  $(document.body).addClass(skin)), \
  ((e) ->
    skin = $('div#theme select').first().val()
    $(document.body).removeClass (index,css) ->
      return (css.match(/\bskin-\S+/g) || []).join(' ')
    $(document.body).addClass(skin))

$('#site-colors > label').click (e) ->
  skin = $(this).find("input").val()
  $(document.body).removeClass (index,css) ->
    return (css.match(/\bskin-\S+/g) || []).join(' ')
  $(document.body).addClass(skin)
  $('div#theme select').first().val(skin)
  $('#site-shades > label').removeClass('active').filter('.style-dark').addClass('active')

$('#site-shades > label').hover ((e) ->
    shade = if $(this).find("input").val() == 'light' then '-light' else ''
    skin = $(document.body).attr('class').match(/skin-[^- ]+/)
    $(document.body).removeClass (index,css) ->
      return (css.match(/\bskin-\S+/g) || []).join(' ')
    $(document.body).addClass(skin + shade)), \
  ((e) ->
    skin = $('div#theme select').first().val()
    $(document.body).removeClass (index,css) ->
      return (css.match(/\bskin-\S+/g) || []).join(' ')
    $(document.body).addClass(skin))

$('#site-shades > label').click (e) ->
  shade = if $(this).find("input").val() == 'light' then '-light' else ''
  skin = $(document.body).attr('class').match(/skin-[^- ]+/)
  $(document.body).removeClass (index,css) ->
    return (css.match(/\bskin-\S+/g) || []).join(' ')
  $(document.body).addClass(skin + shade)
  $('div#theme select').first().val(skin + shade)

skin = $('div#theme select').first().val()
if (skin)
  color = skin.split('-')[1]
  shade = skin.split('-')[2] || 'dark'
  $('#site-colors > label').removeClass('active').filter('.style-'+color).addClass('active')
  $('#site-shades > label').removeClass('active').filter('.style-'+shade).addClass('active')

