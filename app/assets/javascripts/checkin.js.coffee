#= require jquery
#= require jquery_ujs
#= require sonicnet
#= require DYMO.Label.Framework
#= require ./app/center

class Checkin

  checkedIn: {}
  people: {}

  load: (attendance_records) ->
    for person_id, data of attendance_records
      @people[person_id]?.load(data)

  render: ->
    $(document).on 'click', '.checkin-select-person', @selectPerson
    $('.checkin-select-person').each (i, elm) =>
      id = $(elm).data('id')
      @people[id] = new CheckinPerson($("#person_#{id}"))
    $('#add-a-guest').click(@addGuest)
    $('.print-btn').click(@print)
    $('.cancel-btn').click(@cancel)
    @guest = new AddGuest($('.add-a-guest-entry'))
    #if SonicProtocol.isSupported()
      #@sp = new SonicProtocol()
      #@sp.listen()
    @

  selectPerson: (e) =>
    e.preventDefault()
    id = $(e.delegateTarget).data('id')
    @showPerson(id)

  showPerson: (id) =>
    p.hide() for _, p of @people
    @people[id].show()

  addGuest: (e) =>
    e.preventDefault()
    @guest.show()

  addPerson: (id, name) =>
    @people[id] = new CheckinPerson($("#person_#{id}"))

  personCheckedIn: (id, times) =>
    @checkedIn[id] = times
    if (id for id, s of times when s != null).length > 0
      $('.checkin-actions').show().find('.tag-count').text(@tagCount())
    else
      $('.checkin-actions').find('.tag-count').text(@tagCount())
      $('.checkin-actions').hide() if @tagCount() == 0

  tagCount: =>
    count = 0
    for _, times of @checkedIn
      count++ if (id for id, s of times when s != null).length > 0
    count

  print: (e) =>
    e.preventDefault()
    $.ajax "/checkin.json",
      data: JSON.stringify(people: @checkedIn)
      contentType: 'application/json; charset=utf-8'
      dataType: 'json'
      method: 'put'
      complete: (resp) =>
        if new CheckinLabelSet(resp.responseJSON).print()
          location.href = '/checkin'

  cancel: (e) =>
    e.preventDefault()
    location.href = '/checkin'


class AddGuest

  constructor: (@elm) ->
    @elm.find('.save-btn').click(@save)
    @elm.find('.checkin-close').click(@hide)
    @input = @elm.find('input')
    @input.on 'keyup', @keypress
    @person_id = 1

  show: =>
    @elm.show().find('input')[0].focus()

  hide: =>
    @elm.hide()

  keypress: (e) =>
    if e.keyCode == 13
      @save(e)

  save: (e) =>
    e.preventDefault()
    id = @person_id++
    buttons = $('.checkin-people')
    button = buttons.find('a[data-id="new"]')
      .clone()
      .data('id', "new#{id}")
    name = @input.val()
    button.find('.name').html(name)
    buttons.append($('<li>').append(button))
    @input.val('')
    checkin.addPerson(id, name)
    checkin.showPerson(id)
    @hide()


class CheckinPerson

  constructor: (@elm) ->
    @id = @elm.data('id')
    @button = $(".checkin-select-person[data-id='#{@id}']")
    @times = {}
    for time in @elm.find('.checkin-time')
      @times[$(time).data('id')] = new CheckinTime($(time), this)
    @elm.find('.same-as-last-week').click(@sameAsLastWeek)

  load: (data) =>
    for checkin_time_id, records of data
      @times[checkin_time_id]?.load(records)

  show: =>
    @elm.show()
    @button.addClass('active')
    t.show() for _, t of @times

  hide: =>
    @elm.hide()
    t.hide() for _, t of @times
    @button.removeClass('active')

  sameAsLastWeek: (e) =>
    e.preventDefault()
    elm = $(e.delegateTarget)
    for id in elm.data('ids').split(',')
      [time_id, group_id] = id.split('-')
      @times[time_id]?.load([{group_id: group_id}])

  classSelected: (id) =>
    @elm.find('.checkin-same').hide()
    @selected = true
    @button.find('.status').removeClass('fa-chevron-right').addClass('fa-check text-green')
    checkin.personCheckedIn(@id, @selections())

  classUnselected: (id) =>
    count = (t for _, t of @times when t.selected).length
    if count == 0
      @elm.find('.checkin-same').show()
      @selected = false
      @button.find('.status').removeClass('fa-check text-green').addClass('fa-chevron-right')
    checkin.personCheckedIn(@id, @selections())

  selections: =>
    obj = {}
    for id, time of @times
      obj[id] = time.selected
    obj


class CheckinTime

  selected: null

  constructor: (@elm, @person) ->
    @id = @elm.data('id')
    @elm.find('.checkin-open-section').on 'click', @openSection
    @elm.find('.checkin-select-class').on 'click', @selectClass
    @elm.find('.checkin-close').on 'click', @closeTime
    @elm.find('.checkin-open').on 'click', @openTime
    @elm.find('.checkin-change').on 'click', @clearClassAndOpenTime
    @

  load: (data) =>
    for attendance_record in data
      @elm.find(".checkin-select-class[data-group-id='#{attendance_record.group_id}']")
        .click()

  show: =>
    @elm.show()

  hide: =>
    @elm.hide()

  openSection: (e) =>
    e.preventDefault()
    elm = $(e.delegateTarget)
    expanded = elm.hasClass('expanded')
    id = elm.data('id')
    @elm.find('.class-list.indented').hide()
    @elm.find('.checkin-open-section').removeClass('expanded')
    unless expanded
      elm.addClass('expanded')
      $(id).show()

  selectClass: (e) =>
    e.preventDefault()
    elm = $(e.delegateTarget)
    @elm.find('.box-body').hide()
    id = elm.data('id')
    name = elm.find('.name').html()
    @elm.find('.checkin-selection-header').html(
      "<i class='fa fa-check'></i> " +
      name
    )
    @elm.find('.checkin-not-attending-header').hide()
    @elm.addClass('selection-made')
    @elm.find('.checkin-close').hide()
    @elm.find('.checkin-change').show()
    @selected = id
    @person.classSelected(@selected)

  closeTime: (e) =>
    e.preventDefault()
    elm = $(e.delegateTarget)
    @elm.find('.box-body').hide()
    @elm.find('.checkin-close').hide()
    @elm.find('.checkin-open').show()
    @elm.find('.checkin-not-attending-header').show()

  clearClassAndOpenTime: (e) =>
    e.preventDefault()
    elm = $(e.delegateTarget)
    @elm.find('.checkin-selection-header').html('')
    @elm.removeClass('selection-made')
    @elm.find('.checkin-open, .checkin-change').hide()
    @selected = null
    @person.classUnselected(@selected)
    @openTime(e)

  openTime: (e) =>
    e.preventDefault()
    elm = $(e.delegateTarget)
    @elm.find('.box-body').show()
    @elm.find('.checkin-close').show()
    @elm.find('.checkin-open').hide()
    @elm.find('.checkin-not-attending-header').hide()


class SonicProtocol

  @isSupported: ->
    window.webkitAudioContext?

  constructor: () ->
    @audioContext = new webkitAudioContext();
    @alpha = '0123456789.';
    @

  listen: =>
    console.log 'listen'
    @sserver = new SonicServer(alphabet: @alpha)
    @sserver.on 'message', (message) ->
      alert 'Not implimented: Print tags for ' + message.replace(/\./g,'')
    @sserver.start()

  send: (message) =>
    ssocket = new SonicSocket(
      alphabet: @alpha
      charDuration: 0.1
    )
    ssocket.send message.split('').join('.')


class CheckinLabelSet

  constructor: (@data) ->
    by_label_id = {}
    for _, labels of @data.labels
      for l in labels
        data = $.extend {}, l, @data
        code = data.barcode_id.substring(data.barcode_id.length-4)
        by_label_id[data.label_id] ||= new dymo.label.framework.LabelSetBuilder()
        label = by_label_id[data.label_id].addRecord()
        label.setText("COMMUNITY_NAME", data.community_name || '')
        label.setText("FIRST_NAME",     data.first_name     || '')
        label.setText("LAST_NAME",      data.last_name      || '')
        label.setText("DATE",           data.today          || '')
        label.setText("NOTES",          data.medical_notes  || '')
        label.setText("CODE",           code                || '')
        label.setText("SYMBOL",         data.symbol         || '')
    @labels = by_label_id

  print: =>
    printers = (p for p in dymo.label.framework.getPrinters() \
                when p.printerType == 'LabelWriterPrinter')
    if printers.length > 0
      printer = printers[0].name
      for label_id, label_set of @labels
        xml = checkin_labels[label_id]
        dymo.label.framework.openLabelXml(xml).print(printer, '', label_set)
      true
    else
      alert('LabelWriter not found. You may need "Allow" access to the printer in your browser.')
      false


window.checkin = new Checkin().render()
