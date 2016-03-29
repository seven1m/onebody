$ ->
  $('#subset_filter').on('input', ->
    subsetFilter = $(this).val().toLowerCase()
    if subsetFilter != ""
      $('.checkbox-inline[data-keywords]').addClass('hidden')
        .filter( ->
          $(this).attr('data-keywords')
                 .lastIndexOf(subsetFilter) != -1
          ).removeClass('hidden')
      displaySubsetFilterMore()
    else
      maxSubsetFilter()
    )
  $('#subset_more').on('click', ->
    $('.checkbox-inline[data-keywords].hidden').removeClass('hidden')
    displaySubsetFilterMore()
  )
  $('input[name=message\\[member_ids\\]\\[\\]]').on('click', ->
    brandAsSubset()
  )
  maxSubsetFilter()
maxSubsetFilter = ->
  $('.checkbox-inline[data-keywords]').removeClass('hidden')
    .filter((i) -> (i > 4)).addClass('hidden')
  displaySubsetFilterMore()
displaySubsetFilterMore = ->
  if $('.checkbox-inline[data-keywords].hidden').length > 0
    $('#subset_more.hidden').removeClass('hidden')
  else
    $('#subset_more').filter(-> $('#subset_more.hidden').length == 0
    ).addClass('hidden')
  $('.checkbox-inline[data-keywords].hidden input:checked').parent().removeClass('hidden')
brandAsSubset = ->
  if $('input[name=message\\[member_ids\\]\\[\\]]:checked').length == 0
    $('.group-description.hidden').removeClass('hidden')
    $('.subset-description').addClass('hidden')
    $('.subset-warning').addClass('hidden')
  else
    $('.group-description').addClass('hidden')
    $('.subset-description.hidden').removeClass('hidden')
    $('.subset-warning.hidden').removeClass('hidden')
