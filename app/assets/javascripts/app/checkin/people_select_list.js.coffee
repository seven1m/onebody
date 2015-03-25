this.Checkin ?= {}

{ul} = React.DOM

Checkin.PeopleSelectList = React.createFactory React.createClass

  displayName: 'PeopleSelectList'

  render: ->
    ul
      className: 'list-unstyled checkin-people'
      @renderButtons()

  renderButtons: ->
    for person in @props.people
      Checkin.PersonSelectButton
        key: person.id
        person: person
        checkedIn: @getCheckedIn(person)
        onClick: @props.onSelect
        selectedPersonId: @props.selectedPersonId

  getCheckedIn: (person) ->
    all = @props.selections[person.id] || {}
    (time for time, selection of all when selection).length > 0
