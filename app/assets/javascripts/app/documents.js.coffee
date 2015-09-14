$(document).on 'click', '.add-group-to-folder-button', (e) ->
  list = $('#share-with-these-groups').show().find('ul')
  for input in $('#group_results input:checked')
    elm = $(input)
    id = elm.val()
    name = elm.data('name')
    input = $("<input type='checkbox' id='group#{id}' name='folder[group_ids][]' value='#{id}' checked>")
    label = $("<label for='group#{id}'>#{name}</label>")
    li = $('<li/>').append(input).append(document.createTextNode(' ')).append(label)
    list.append(li)
    $('#add_group').hide()

$('#document-visibility input[type="checkbox"]').click (e) ->
  form = $(e.target).parents('form')
  args = form.serialize()
  args += '&hidden_folders=false' unless args.match(/hidden_folders/)
  args += '&restricted_folders=false' unless args.match(/restricted_folders/)
  location.href = '?' + args

$('#document_file').change (e) ->
  if ( e.target.files.length == 0 )
    $('#document_table > tbody > tr:not(:first-child)').empty()
    $('#document_table > tbody:last-child').append( documentUploadTemplate.clone() )
    return
  if window.location.search.indexOf('multiple_documents=true') > -1
    $('#document_table > tbody > tr:not(:first-child)').empty()
		id_count = 0
		for file in e.target.files
      row = $(documentUploadTemplate).clone()
      row.find('td > .form-group > label').first().html( file.name )
      $('#document_table > tbody:last-child').append( row )
      id_count++
  name = e.target.files[0].name
  $('#document_name').val(name)

window.documentUploadTemplate = $( $('#document_table > tbody > tr')[1] ).clone()
