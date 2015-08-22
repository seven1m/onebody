this.Checkin ?= {}

class Checkin.LabelSet
  constructor: (@data, @label_templates) ->
    by_label_id = {}
    for _, labels of @data.labels when labels
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
        xml = @label_templates[label_id]
        dymo.label.framework.openLabelXml(xml).print(printer, '', label_set)
      true
    else
      alert('LabelWriter not found. You may need "Allow" access to the printer in your browser.')
      false
