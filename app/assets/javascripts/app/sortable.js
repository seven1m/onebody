$('.sortable').each(function(i, container) {
  new Sortable(
    container,
    {
      handle: '.handle',

      onUpdate: function(event) {
        var target = $(event.target)
        var index = target.parent().children().index(event.target)
        $.post(target.data('update-position-path'), { position: index + 1 })
      }
    }
  )
})
