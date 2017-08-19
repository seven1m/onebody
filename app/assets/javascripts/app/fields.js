function idFromDomId(id) {
  return id.match(/\d+$/)[0]
}

sortables = []

function setupCustomFieldSortable() {
  sortables.forEach(function(s) { s.destroy() })
  sortables = []
  $('.custom-fields').each(function(i, container) {
    var tabId = idFromDomId($(container).parents('.well')[0].id)
    var sortable = new Sortable(
      $(container).find('tbody')[0],
      {
        group: 'fields',
        handle: '.handle',
        scroll: true,

        onUpdate: function(event) {
          var target = $(event.target)
          var index = target.parent().children().index(event.target)
          var id = idFromDomId(event.target.id)
          console.log(index)
          $.ajax({
            url: '/admin/custom_fields/' + id + '.js',
            method: 'PATCH',
            data: {
              custom_field: {
                position: index + 1
              }
            }
          })
        },

        onAdd: function(event) {
          var id = idFromDomId(event.target.id)
          var parent = $(event.target).parent()
          var index = parent.children().index(event.target)
          if (parent.find('tr.ignore').length) index--
          $.ajax({
            url: '/admin/custom_fields/' + id + '.js',
            method: 'PATCH',
            data: {
              custom_field: {
                tab_id: tabId,
                position: index + 1
              }
            }
          })
        },
      }
    )
    sortables.push(sortable)
  })
}

setupCustomFieldSortable()
