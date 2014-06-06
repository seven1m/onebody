class PhotoForm

  constructor: (@el) ->
    @input_group = @el.find('.file-upload-group').hide()
    @upload_button = @el.find('.upload-button').hide().click @upload
    @browse_button = @el.find('.photo-browse').show().click @browse
    @delete_button = @el.find('.photo-delete').click @delete
    @uploading_status = @el.find('.photo-selected')
    @error_callout = @el.find('.photo-error')
    @input = @el.find('input[type="file"]').change @select
    @url = @el.data('upload-url')
    @id = @el.data('object-id')

  browse: (e) =>
    e.preventDefault()
    @input.trigger('click')

  select: (e) =>
    @uploading_status.show().find('.filename').text(@input.val())
    if @url and @can_upload()
      if @valid_type()
        @error_callout.hide().find('.wrong-type').hide()
        @upload_button.show()
      else
        @uploading_status.hide()
        @error_callout.show().find('.wrong-type').show()

  can_upload: =>
    typeof(window.FormData) != 'undefined'

  valid_type: =>
    file = @input[0].files[0]
    file.type.match(/^image\//) and file.name.toLowerCase().match(/\.(jpg|jpeg|png|gif)/)

  upload: (e) =>
    e.preventDefault()
    url = @el.data('upload-url') + '.json'
    @upload_button.addClass('disabled')
    @spinner = new Spinner(radius: 5, length: 5, width: 2).spin(@uploading_status[0])
    data = new FormData()
    data.append 'photo', @input[0].files[0]
    $.ajax
      url: url
      type: 'PUT'
      data: data
      cache: false,
      dataType: 'json'
      processData: false
      contentType: false
      complete: (d) =>
        @spinner.stop()
        @upload_button.removeClass('disabled').hide()
        @uploading_status.hide()
        response = d.responseJSON
        if response.status == 'success'
          @updateAll(response.photo)
          @delete_button.show()
          @error_callout.hide()
        else
          @error_callout.show().find('.body').html(response.errors.join("<br>"))

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
