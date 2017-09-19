var color, i, len, ref, section, shade, skin;

ref = $('.collapsable-heading');
for (i = 0, len = ref.length; i < len; i++) {
  section = ref[i];
  section = $(section);
  if (section.find('.box, .small-box').length === 0) {
    section.find('h2').hide();
  }
}

$('div#theme select').first().change(function(e) {
  var color, shade, skin;
  $(document.body).removeClass(function(index, css) {
    return (css.match(/\bskin-\S+/g) || []).join(' ');
  });
  skin = $(this).val();
  color = skin.split('-')[1];
  shade = skin.split('-')[2] || 'dark';
  $(document.body).addClass(skin);
  $('#site-colors > label').removeClass('active').filter('.style-' + color).addClass('active');
  return $('#site-shades > label').removeClass('active').filter('.style-' + shade).addClass('active');
});

$('#site-colors > label').hover((function(e) {
  var skin;
  skin = $(this).find("input").val();
  $(document.body).removeClass(function(index, css) {
    return (css.match(/\bskin-\S+/g) || []).join(' ');
  });
  return $(document.body).addClass(skin);
}), (function(e) {
  var skin;
  skin = $('div#theme select').first().val();
  $(document.body).removeClass(function(index, css) {
    return (css.match(/\bskin-\S+/g) || []).join(' ');
  });
  return $(document.body).addClass(skin);
}));

$('#site-colors > label').click(function(e) {
  var skin;
  skin = $(this).find("input").val();
  $(document.body).removeClass(function(index, css) {
    return (css.match(/\bskin-\S+/g) || []).join(' ');
  });
  $(document.body).addClass(skin);
  $('div#theme select').first().val(skin);
  return $('#site-shades > label').removeClass('active').filter('.style-dark').addClass('active');
});

$('#site-shades > label').hover((function(e) {
  var shade, skin;
  shade = $(this).find("input").val() === 'light' ? '-light' : '';
  skin = $(document.body).attr('class').match(/skin-[^- ]+/);
  $(document.body).removeClass(function(index, css) {
    return (css.match(/\bskin-\S+/g) || []).join(' ');
  });
  return $(document.body).addClass(skin + shade);
}), (function(e) {
  var skin;
  skin = $('div#theme select').first().val();
  $(document.body).removeClass(function(index, css) {
    return (css.match(/\bskin-\S+/g) || []).join(' ');
  });
  return $(document.body).addClass(skin);
}));

$('#site-shades > label').click(function(e) {
  var shade, skin;
  shade = $(this).find("input").val() === 'light' ? '-light' : '';
  skin = $(document.body).attr('class').match(/skin-[^- ]+/);
  $(document.body).removeClass(function(index, css) {
    return (css.match(/\bskin-\S+/g) || []).join(' ');
  });
  $(document.body).addClass(skin + shade);
  return $('div#theme select').first().val(skin + shade);
});

skin = $('div#theme select').first().val();

if (skin) {
  color = skin.split('-')[1];
  shade = skin.split('-')[2] || 'dark';
  $('#site-colors > label').removeClass('active').filter('.style-' + color).addClass('active');
  $('#site-shades > label').removeClass('active').filter('.style-' + shade).addClass('active');
}
