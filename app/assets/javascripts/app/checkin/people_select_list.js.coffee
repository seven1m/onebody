{ul} = React.DOM

Checkin.PeopleSelectList = React.createClass

  displayName: 'PeopleSelectList'

  render: ->
    ul(className: 'list-unstyled checkin-people',
      @renderButtons())

  renderButtons: ->
    for person in @props.people
      Checkin.PersonSelectButton
        person: person
        checkedIn: person.attendance_records.length > 0
        onClick: @props.onSelect
