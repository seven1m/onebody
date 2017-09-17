const csrf_token = $('meta[name="csrf-token"]').attr('content')
if (csrf_token) {
  $(document).ajaxSend((_, xhr) => {
    xhr.setRequestHeader('X-CSRF-Token', csrf_token)
  })
}
