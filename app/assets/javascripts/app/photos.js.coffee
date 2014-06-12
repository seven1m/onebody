class PhotoForm

  constructor: (@el) ->
    @input_group = @el.find('.file-upload-group').hide()
    @browse_button = @el.find('.photo-browse').show().click @browse
    @delete_button = @el.find('.photo-delete').click @delete
    @uploading_status = @el.find('.photo-selected')
    @upload_button = @el.find('.upload-button').hide()
    @progress = @el.find('.progress')
    @error_callout = @el.find('.photo-error')
    @input = @el.find('input[type="file"]').change @select
    @url = @el.data('upload-url')
    @id = @el.data('object-id')

  browse: (e) =>
    e.preventDefault()
    @input.trigger('click')

  select: (e) =>
    if @url and @can_upload() and @valid_type()
      @uploading_status.show().find('.filename').text((f.name for f in @input[0].files).join(', '))
      @error_callout.hide().find('.wrong-type').hide()
      @upload()
    else if not @valid_type()
      @uploading_status.hide()
      @error_callout.show().find('.wrong-type').show()

  can_upload: =>
    typeof(window.FormData) != 'undefined'

  valid_type: =>
    file = @input[0].files[0]
    file.type.match(/^image\//) and file.name.toLowerCase().match(/\.(jpg|jpeg|png|gif)/)

  show_progress: (pct) =>
    if pct != null
      @progress.show().find('.progress-bar').css('width', pct + '%')
    else
      @progress.hide()

  upload: (e) =>
    e?.preventDefault()
    @show_progress(25)
    url = @el.data('upload-url') + '.json'
    data = new FormData()
    if @input.attr('multiple')
      for file in @input[0].files
        data.append @el.data('upload-field-name'), file
    else
      data.append @el.data('upload-field-name'), @input[0].files[0]
    $.ajax
      url: url
      type: @el.data('upload-verb') || 'PUT'
      data: data
      cache: false,
      dataType: 'json'
      processData: false
      contentType: false
      complete: (d) =>
        @show_progress(100)
        setTimeout (=> @show_progress(null)), 800
        @uploading_status.hide()
        response = d.responseJSON
        if response.status == 'reload'
          location.reload()
        else if response.status == 'success'
          @updateAll(response.photo)
          @delete_button.show()
          @error_callout.hide()
        else
          @error_callout.show().find('.body').html(response.errors.join("<br>"))
      xhr: =>
        x = jQuery.ajaxSettings.xhr()
        progress = (e) =>
          @show_progress(e.loaded / e.total) if e.lengthComputable
        x.upload.addEventListener 'progress', progress, false
        return x

  delete: (e) =>
    e.preventDefault()
    if confirm(@delete_button.data('confirm-message'))
      $.ajax
        url: @delete_button.attr('href') + '.json'
        type: 'DELETE'
        complete: (d) =>
          response = d.responseJSON
          if response.status == 'deleted'
            @updateAll(response.placeholder)
            @delete_button.hide()
            @error_callout.hide()

  updateAll: (sizes) =>
    for img in $("[data-id=\"#{@id}\"]")
      size = $(img).data('size')
      $(img).attr('src', sizes[size] + '?' + Math.random())

window.photo_form = new PhotoForm($('.photo-upload'))
