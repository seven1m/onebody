class SearchVerseForm

  constructor: (@el) ->
    @el.submit @search
    @result = $('#search_result')
    @error_message = $('#search_error')

  search: (e) =>
    e.preventDefault()
    @error_message.hide()
    query = @el.find('#q').val()
    $.ajax
      url: '/verses/search'
      type: 'GET'
      data: {q: query}
      complete: @showResult
      error: @showError

  showResult: (data, status) =>
    @result.html(data.responseText) if status is 'success'
    @showError() if status isnt 'success'

  showError: =>
    @result.empty()
    @error_message.show()

window.verse_form = (new SearchVerseForm($(f)) for f in $('#search_verse_form'))
