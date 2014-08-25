$.fn.highlight = (duration=1000) ->
  this.css('background-color', '#ff9')
      .stop()
      .animate({'background-color': 'transparent'}, duration);
