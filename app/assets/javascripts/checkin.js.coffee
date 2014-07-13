#= require jquery
#= require jquery_ujs
#= require sonicnet
#= require ./app/center

class Checkin

  checkedIn: {}
  people: {}

  load: (attendance_records) ->
    for person_id, data of attendance_records
      @people[person_id]?.load(data)

  render: ->
    $('.checkin-select-person').click(@selectPerson).each (i, elm) =>
      id = $(elm).data('id')
      @people[id] = new CheckinPerson($("#person_#{id}"))
    $('#add-a-guest').click(@addGuest)
    $('.checkin-print .btn').click(@print)
    #if SonicProtocol.isSupported()
      #@sp = new SonicProtocol()
      #@sp.listen()
    @

  selectPerson: (e) =>
    e.preventDefault()
    p.hide() for _, p of @people
    id = $(e.delegateTarget).data('id')
    @people[id].show()

  addGuest: (e) =>
    e.preventDefault()
    alert('NOT YET IMPLEMENTED')

  personCheckedIn: (id, times) =>
    @checkedIn[id] = times
    if (id for id, s of times when s != null).length > 0
      $('.checkin-print').show().find('.tag-count').text(@tagCount())
    else
      $('.checkin-print').find('.tag-count').text(@tagCount())
      $('.checkin-print').hide() if @tagCount() == 0

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
        new CheckinLabelSet(resp.responseJSON).print()
        location.href = '/checkin'


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
    @labelSet = new dymo.label.framework.LabelSetBuilder()
    labels = []
    for _, labels of @data.labels
      for l in labels
        data = $.extend {}, l, @data
        code = data.barcode_id.substring(data.barcode_id.length-4)
        label = @labelSet.addRecord()
        label.setText("COMMUNITY_NAME", data.community_name || '')
        label.setText("FIRST_NAME",     data.first_name     || '')
        label.setText("LAST_NAME",      data.last_name      || '')
        label.setText("DATE",           data.today          || '')
        label.setText("NOTES",          data.medical_notes  || '')
        label.setText("CODE",           code                || '')

  labelXml: ->
    """
      <?xml version="1.0" encoding="utf-8"?>
      <DieCutLabel Version="8.0" Units="twips">
        <PaperOrientation>Landscape</PaperOrientation>
        <Id>Address</Id>
        <PaperName>30252 Address</PaperName>
        <DrawCommands>
          <RoundRectangle X="0" Y="0" Width="1581" Height="5040" Rx="270" Ry="270"/>
        </DrawCommands>
        <ObjectInfo>
          <TextObject>
            <Name>CODE</Name>
            <ForeColor Alpha="255" Red="0" Green="0" Blue="0"/>
            <BackColor Alpha="0" Red="255" Green="255" Blue="255"/>
            <LinkedObjectName></LinkedObjectName>
            <Rotation>Rotation0</Rotation>
            <IsMirrored>False</IsMirrored>
            <IsVariable>True</IsVariable>
            <HorizontalAlignment>Right</HorizontalAlignment>
            <VerticalAlignment>Middle</VerticalAlignment>
            <TextFitMode>AlwaysFit</TextFitMode>
            <UseFullFontHeight>True</UseFullFontHeight>
            <Verticalized>False</Verticalized>
            <StyledText>
              <Element>
                <String>1234</String>
                <Attributes>
                  <Font Family="Helvetica CY" Size="13" Bold="False" Italic="False" Underline="False" Strikeout="False"/>
                  <ForeColor Alpha="255" Red="0" Green="0" Blue="0"/>
                </Attributes>
              </Element>
            </StyledText>
          </TextObject>
          <Bounds X="1111.793" Y="432.1721" Width="3841.807" Height="952.442"/>
        </ObjectInfo>
        <ObjectInfo>
          <TextObject>
            <Name>FIRST_NAME</Name>
            <ForeColor Alpha="255" Red="0" Green="0" Blue="0"/>
            <BackColor Alpha="0" Red="255" Green="255" Blue="255"/>
            <LinkedObjectName></LinkedObjectName>
            <Rotation>Rotation0</Rotation>
            <IsMirrored>False</IsMirrored>
            <IsVariable>True</IsVariable>
            <HorizontalAlignment>Left</HorizontalAlignment>
            <VerticalAlignment>Middle</VerticalAlignment>
            <TextFitMode>ShrinkToFit</TextFitMode>
            <UseFullFontHeight>True</UseFullFontHeight>
            <Verticalized>False</Verticalized>
            <StyledText>
              <Element>
                <String>First Name</String>
                <Attributes>
                  <Font Family="Helvetica" Size="24" Bold="False" Italic="False" Underline="False" Strikeout="False"/>
                  <ForeColor Alpha="255" Red="0" Green="0" Blue="0"/>
                </Attributes>
              </Element>
            </StyledText>
          </TextObject>
          <Bounds X="331.2" Y="340.1532" Width="2540" Height="600"/>
        </ObjectInfo>
        <ObjectInfo>
          <TextObject>
            <Name>LAST_NAME</Name>
            <ForeColor Alpha="255" Red="0" Green="0" Blue="0"/>
            <BackColor Alpha="0" Red="255" Green="255" Blue="255"/>
            <LinkedObjectName></LinkedObjectName>
            <Rotation>Rotation0</Rotation>
            <IsMirrored>False</IsMirrored>
            <IsVariable>True</IsVariable>
            <HorizontalAlignment>Left</HorizontalAlignment>
            <VerticalAlignment>Middle</VerticalAlignment>
            <TextFitMode>ShrinkToFit</TextFitMode>
            <UseFullFontHeight>True</UseFullFontHeight>
            <Verticalized>False</Verticalized>
            <StyledText>
              <Element>
                <String>Long Last Name Here</String>
                <Attributes>
                  <Font Family="Helvetica" Size="13" Bold="False" Italic="False" Underline="False" Strikeout="False"/>
                  <ForeColor Alpha="255" Red="0" Green="0" Blue="0"/>
                </Attributes>
              </Element>
            </StyledText>
          </TextObject>
          <Bounds X="347.6253" Y="751.9824" Width="2540" Height="572.9443"/>
        </ObjectInfo>
        <ObjectInfo>
          <TextObject>
            <Name>COMMUNITY_NAME</Name>
            <ForeColor Alpha="255" Red="0" Green="0" Blue="0"/>
            <BackColor Alpha="0" Red="255" Green="255" Blue="255"/>
            <LinkedObjectName></LinkedObjectName>
            <Rotation>Rotation0</Rotation>
            <IsMirrored>False</IsMirrored>
            <IsVariable>True</IsVariable>
            <HorizontalAlignment>Left</HorizontalAlignment>
            <VerticalAlignment>Middle</VerticalAlignment>
            <TextFitMode>ShrinkToFit</TextFitMode>
            <UseFullFontHeight>True</UseFullFontHeight>
            <Verticalized>False</Verticalized>
            <StyledText>
              <Element>
                <String>Cedar Ridge Christian Church</String>
                <Attributes>
                  <Font Family="Helvetica CY" Size="8" Bold="False" Italic="False" Underline="False" Strikeout="False"/>
                  <ForeColor Alpha="255" Red="0" Green="0" Blue="0"/>
                </Attributes>
              </Element>
            </StyledText>
          </TextObject>
          <Bounds X="374.0861" Y="96.98391" Width="4560.615" Height="296.0015"/>
        </ObjectInfo>
        <ObjectInfo>
          <TextObject>
            <Name>DATE</Name>
            <ForeColor Alpha="255" Red="0" Green="0" Blue="0"/>
            <BackColor Alpha="0" Red="255" Green="255" Blue="255"/>
            <LinkedObjectName></LinkedObjectName>
            <Rotation>Rotation0</Rotation>
            <IsMirrored>False</IsMirrored>
            <IsVariable>True</IsVariable>
            <HorizontalAlignment>Right</HorizontalAlignment>
            <VerticalAlignment>Middle</VerticalAlignment>
            <TextFitMode>ShrinkToFit</TextFitMode>
            <UseFullFontHeight>True</UseFullFontHeight>
            <Verticalized>False</Verticalized>
            <StyledText>
              <Element>
                <String>July 13, 2014</String>
                <Attributes>
                  <Font Family="Helvetica CY" Size="8" Bold="False" Italic="False" Underline="False" Strikeout="False"/>
                  <ForeColor Alpha="255" Red="0" Green="0" Blue="0"/>
                </Attributes>
              </Element>
            </StyledText>
          </TextObject>
          <Bounds X="3227.97" Y="57.59995" Width="1674.069" Height="357.5321"/>
        </ObjectInfo>
        <ObjectInfo>
          <TextObject>
            <Name>NOTES</Name>
            <ForeColor Alpha="255" Red="0" Green="0" Blue="0"/>
            <BackColor Alpha="0" Red="255" Green="255" Blue="255"/>
            <LinkedObjectName></LinkedObjectName>
            <Rotation>Rotation0</Rotation>
            <IsMirrored>False</IsMirrored>
            <IsVariable>True</IsVariable>
            <HorizontalAlignment>Left</HorizontalAlignment>
            <VerticalAlignment>Middle</VerticalAlignment>
            <TextFitMode>ShrinkToFit</TextFitMode>
            <UseFullFontHeight>True</UseFullFontHeight>
            <Verticalized>False</Verticalized>
            <StyledText>
              <Element>
                <String>Medical notes go here.</String>
                <Attributes>
                  <Font Family="Lucida Grande" Size="13" Bold="False" Italic="False" Underline="False" Strikeout="False"/>
                  <ForeColor Alpha="255" Red="0" Green="0" Blue="0"/>
                </Attributes>
              </Element>
            </StyledText>
          </TextObject>
          <Bounds X="370.1779" Y="1250.467" Width="4483.545" Height="213.9854"/>
        </ObjectInfo>
      </DieCutLabel>
    """

  print: =>
    printers = (p for p in dymo.label.framework.getPrinters() \
                when p.printerType == 'LabelWriterPrinter')
    if printers.length > 0
      printer = printers[0].name
      to_print = dymo.label.framework.openLabelXml(@labelXml())
      to_print.print(printer, '', @labelSet);
    else
      alert('LabelWriter not found')


window.checkin = new Checkin().render()
