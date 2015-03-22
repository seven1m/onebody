class PhotoForm

  constructor: (@el) ->
    @input_group = @el.find('.file-upload-group').hide()
    @drag_area = @input_group.parents('.photo-drop-area').on('drop', @drop)
    @browse_button = @el.find('.photo-browse').show().click @browse
    @delete_button = @el.find('.photo-delete').click @delete
    @uploading_status = @el.find('.photo-selected')
    @upload_button = @el.find('.upload-button').hide()
    @progress = @el.find('.progress')
    @error_callout = @el.find('.photo-error')
    @input = @el.find('input[type="file"]').change @select
    @url = @el.data('upload-url')
    @id = @el.data('object-id')
    @img = @el.parents('.photo-drop-area').find('img')

  browse: (e) =>
    e.preventDefault()
    @input.trigger('click')

  drop: (e) =>
    e.preventDefault()
    @files = e.originalEvent.dataTransfer.files
    unless @input.attr('multiple')
      @files = [@files[0]]
    @validate() and @upload()

  select: (e) =>
    @files = if @input.attr('multiple')
      @input[0].files
    else
      [@input[0].files[0]]
    if @url and @can_upload()
      @validate() and @upload()
    else
      @showFiles()

  validate: =>
    if @valid_type()
      @showFiles()
      @error_callout.hide().find('.wrong-type').hide()
      true
    else
      @uploading_status.hide()
      @error_callout.show().find('.wrong-type').show()
      false

  showFiles: =>
    @uploading_status.show().find('.filename').text(
      (f.name for f in @files).join(', ')
    )

  can_upload: =>
    typeof(window.FormData) != 'undefined'

  valid_type: =>
    file = @files[0]
    file.type.match(/^image\//) and file.name.toLowerCase().match(/\.(jpg|jpeg|png|gif)/)

  show_progress: (pct) =>
    if pct != null
      @progress.show().find('.progress-bar').css('width', pct + '%')
    else
      @progress.hide()

  upload: (e) =>
    e?.preventDefault()
    @img.addClass('uploading')
    @album_id = @el.parents('form').find('[name="album_id"]').val()
    @show_progress(5)
    @complete = []
    @errors = false
    for file in @files
      @uploadFile(file)

  uploadFile: (file) =>
    data = new FormData()
    data.append(@el.data('upload-field-name'), file)
    data.append('album_id', @album_id) if @album_id
    url = @el.data('upload-url') + '.json'
    $.ajax
      url: url
      type: @el.data('upload-verb') || 'PUT'
      data: data
      cache: false,
      dataType: 'json'
      processData: false
      contentType: false
      complete: (d) =>
        response = d.responseJSON
        @complete.push(file)
        @show_progress(@complete.length / @files.length * 100)
        if @complete.length == @files.length
          @img.removeClass('uploading')
          setTimeout (=> @show_progress(null)), 800
          @uploading_status.hide()
          if response.status == 'success'
            if response.url
              location.href = response.url unless @errors
            else
              @updateAll(response.photo)
              @delete_button.show()
        if response.status != 'success'
          console.log(response)
          @errors = true
          @error_callout.show().find('.body').append(response.errors.join("<br>") + "<br>")

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

window.photo_forms = (new PhotoForm($(f)) for f in $('.photo-upload'))

$(document).on 'dragover', '.photo-drop-area, .photo-drop-area *', (e) -> e.preventDefault()
