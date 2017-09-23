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
  var tabs = $('.custom-field-tabs')
  if (tabs.length > 0) {
    var sortable = new Sortable(
      tabs[0],
      {
        handle: '.handle',
        scroll: true,

        onUpdate: function(event) {
          var index = tabs.children().index(event.target)
          var id = idFromDomId(event.target.id)
          $.ajax({
            url: '/admin/custom_field_tabs/' + id + '.js',
            method: 'PATCH',
            data: {
              custom_field_tab: {
                position: index + 1
              }
            }
          })
        }
      }
    )
    sortables.push(sortable)
  }
}

setupCustomFieldSortable()
