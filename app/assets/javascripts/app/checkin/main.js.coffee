{div} = React.DOM

Checkin.Main = React.createFactory React.createClass

  displayName: 'Main'

  getInitialState: ->
    people: @props.people
    selectedPersonId: null
    selections: @props.selections
    addingGuest: false

  render: ->
    div
      className: 'row'
      div
        className: 'col-lg-3'
        Checkin.PeopleSelectList
          people: @state.people
          selections: @state.selections
          onSelect: @handlePersonSelect
          selectedPersonId: @state.selectedPersonId
        Checkin.AddGuestLink
          onClick: @handleAddGuestLinkClick
          active: @state.addingGuest
        Checkin.ActionButtons
          selections: @state.selections
          onSubmit: @handleSubmit
          onCancel: @handleCancel
      div
        className: 'col-lg-9',
        if @state.selectedPersonId
          Checkin.ClassSelectList
            person: @getPersonById(@state.selectedPersonId)
            times: @props.times
            selections: @state.selections[@state.selectedPersonId] || {}
            onSelect: @handleClassSelect
        if @state.addingGuest
          Checkin.AddGuestBox
            onSubmit: @handleAddGuestSubmit

  handlePersonSelect: (id) ->
    @setState
      selectedPersonId: id
      addingGuest: false

  handleAddGuestLinkClick: ->
    @setState
      selectedPersonId: null
      addingGuest: true

  handleClassSelect: (time, selection) ->
    selections = _(@state.selections).clone()
    selections[@state.selectedPersonId] = _(selections[@state.selectedPersonId] || {}).clone()
    selections[@state.selectedPersonId][time.id] = selection
    @setState(selections: selections)

  handleAddGuestSubmit: (person) ->
    people = _(@state.people).clone()
    people.push(person)
    @setState
      people: people
      selectedPersonId: person.id
      addingGuest: false

  handleSubmit: ->
    $.ajax "/checkin.json",
      data: JSON.stringify(people: @state.selections)
      contentType: 'application/json; charset=utf-8'
      dataType: 'json'
      method: 'put'
      complete: (resp) =>
        if new Checkin.LabelSet(resp.responseJSON, @props.labels).print()
          location.href = '/checkin'

  handleCancel: ->
    location.href = '/checkin'

  getPersonById: (id) ->
    return unless id
    _(@state.people).find (p) -> p.id == id
