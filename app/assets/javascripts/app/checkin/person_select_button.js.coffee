this.Checkin ?= {}

{a, div, i, img, li, span} = React.DOM

Checkin.PersonSelectButton = React.createFactory React.createClass

  displayName: 'PersonSelectButton'

  render: ->
    li
      key: @props.person.id || 'new'
      div
        className: React.addons.classSet
          'btn checkin-btn checkin-select-person': true
          'active': @props.selectedPersonId == @props.person.id
        onClick: @handleClick
        div
          className: 'pull-right'
          @renderIcon()
        img
          src: @getAvatar()
          className: 'avatar tn'
        ' '
        span
          className: 'name'
          @props.person.first_name || 'Add a guest'

  renderIcon: ->
    if @props.checkedIn
      i
        className: 'fa fa-check text-green'
    else
      i
        className: 'fa fa-chevron-right'

  getAvatar: ->
    if @props.person.avatar
      @props.person.avatar
    else if @props.person.gender == 'Female'
      avatars.female
    else
      avatars.male

  handleClick: ->
    @props.onClick(@props.person.id)
