$('.sortable').each((i, container) => {
  new Sortable(
    container,
    {
      handle: '.handle',
      onUpdate: (event) => {
        const target = $(event.target)
        const index = target.parent().children().index(event.target)
        $.post(target.data('update-position-path'), { position: index + 1 })
      }
    }
  )
})
