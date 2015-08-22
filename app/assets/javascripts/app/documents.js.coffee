$(document).on 'click', '.add-group-to-folder-button', (e) ->
  list = $('#share-with-these-groups').show().find('ul')
  for input in $('#group_results input:checked')
    elm = $(input)
    id = elm.val()
    name = elm.data('name')
    input = $("<input type='checkbox' class='form-control' id='group#{id}' name='folder[group_ids][]' value='#{id}' checked>")
    label = $("<label for='group#{id}'>#{name}</label>")
    li = $('<li/>').append(input).append(label)
    list.append(li)
    input.iCheck(checkboxClass: 'icheckbox_minimal')
    $('#add_group').hide()

$('#document-visibility input[type="checkbox"]').click (e) ->
  form = $(e.target).parents('form')
  args = form.serialize()
  args += '&hidden_folders=false' unless args.match(/hidden_folders/)
  args += '&restricted_folders=false' unless args.match(/restricted_folders/)
  location.href = '?' + args
