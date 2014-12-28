class SearchVerseForm

  constructor: (@el) ->
    @el.on 'submit', @search
    @$result = $('#search_result')
    @$errorMessage = $('#search_error')

  search: (e) =>
    e.preventDefault()
    query = @el.find('#q').val()
    $.ajax
      url: '/verses/search'
      type: 'GET'
      data: {q: query}
      success: @showResult
      error: @showError

  showResult: (data) =>
    @$errorMessage.hide()
    @$result.html(data)

  showError: =>
    @$result.empty()
    @$errorMessage.show()

selector = $('#search_verse_form')
new SearchVerseForm(selector) if selector.length isnt 0
