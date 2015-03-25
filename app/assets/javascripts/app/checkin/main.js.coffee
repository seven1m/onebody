this.Checkin ?= {}

{div, span} = React.DOM

Checkin.Main = React.createFactory React.createClass

  displayName: 'Main'

  getDefaultProps: ->
    prints_channel_status: null
    pusher_status: null

  getInitialState: ->
    people: []
    selectedPersonId: null
    selections: @props.selections
    addingGuest: false
    checkinIn: false
    barcodeError: null
    narrowScreen: false

  componentDidMount: ->
    @setNarrowScreen()
    $(window).on 'resize', @setNarrowScreen

  componentWillUnmount: ->
    $(window).off 'resize', @setNarrowScreen

  render: ->
    div {},
      if @state.checkingIn
        @renderSelections()
      else
        if @props.times.length > 0
          Checkin.BarcodeInput
            onSubmit: @handleScanBarcode
            error: @state.barcodeError
        else
          @renderNoTimesAlert()
      div
        className: 'checkin-printer-status'
        if checkin_printer_id
          span {},
            'printer status: '
            @getPrinterStatus()

  renderSelections: ->
    div
      className: 'row'
      div
        className: 'col-md-3'
        Checkin.PeopleSelectList
          people: @state.people
          selections: @state.selections
          onSelect: @handlePersonSelect
          selectedPersonId: @state.selectedPersonId
        unless @state.narrowScreen
          Checkin.AddGuestLink
            onClick: @handleAddGuestLinkClick
            active: @state.addingGuest
          Checkin.ActionButtons
            selections: @state.selections
            onSubmit: @handleSubmit
            onCancel: @handleCancel
      div
        className: 'col-md-9',
        if @state.selectedPersonId
          Checkin.ClassSelectList
            person: @getPersonById(@state.selectedPersonId)
            times: @props.times
            selections: @state.selections[@state.selectedPersonId] || {}
            onSelect: @handleClassSelect
            last_week: @props.last_week
        if @state.addingGuest
          Checkin.AddGuestBox
            onSubmit: @handleAddGuestSubmit
        if @state.narrowScreen
          Checkin.AddGuestLink
            onClick: @handleAddGuestLinkClick
            active: @state.addingGuest
          Checkin.ActionButtons
            selections: @state.selections
            onSubmit: @handleSubmit
            onCancel: @handleCancel

  handlePersonSelect: (id) ->
    @setState
      selectedPersonId: id
      addingGuest: false

  handleAddGuestLinkClick: ->
    @setState
      selectedPersonId: null
      addingGuest: true

  handleClassSelect: (batch) ->
    selections = _(@state.selections).clone()
    selections[@state.selectedPersonId] = _(selections[@state.selectedPersonId] || {}).clone()
    for [time, selection] in batch
      selections[@state.selectedPersonId][time.id] = selection
    @setState(selections: selections)

  handleAddGuestSubmit: (person) ->
    people = _(@state.people).clone()
    people.push(person)
    @setState
      people: people
      selectedPersonId: person.id
      addingGuest: false

  handleScanBarcode: (barcode) ->
    $.ajax '/checkin.json',
      data: JSON.stringify(barcode: barcode)
      contentType: 'application/json; charset=utf-8'
      dataType: 'json'
      method: 'post'
      complete: (resp) =>
        data = resp.responseJSON
        if data.error
          @setState
            barcodeError: data.error
        else
          @setProps(data)
          @setState
            barcodeError: null
            people: data.people
            checkingIn: true

  handleSubmit: ->
    $.ajax '/checkin.json',
      data: JSON.stringify(people: @state.selections)
      contentType: 'application/json; charset=utf-8'
      dataType: 'json'
      method: 'put'
      complete: (resp) =>
        print_label resp.responseJSON, (err) =>
          if err then throw err
          @handleCancel()

  handleCancel: ->
    @setState
      people: []
      checkingIn: false

  getPersonById: (id) ->
    return unless id
    _(@state.people).find (p) -> p.id == id

  getPrinterStatus: ->
    if @props.pusher_status == 'connected' and @props.prints_channel_status
      @props.prints_channel_status
    else if @props.pusher_status
      @props.pusher_status
    else
      'connecting'

  setNarrowScreen: ->
    @setState
      narrowScreen: $(window).width() < 992
