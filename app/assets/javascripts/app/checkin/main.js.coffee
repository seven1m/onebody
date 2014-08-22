{div} = React.DOM

Checkin.Main = React.createClass

  displayName: 'Main'

  getInitialState: ->
    selectedPersonId: null

  render: ->
    div(className: 'row',
      div(className: 'col-lg-3',
        Checkin.PeopleSelectList(
          people: @props.people
          onSelect: @handlePersonSelect)),
      div(className: 'col-lg-9',
        Checkin.ClassSelectList(
          person: @getPersonById(@state.selectedPersonId),
          times: @props.times)))

  handlePersonSelect: (id) ->
    @setState(selectedPersonId: id)

  getPersonById: (id) ->
    return unless id
    _(@props.people).find (p) -> p.id == id
