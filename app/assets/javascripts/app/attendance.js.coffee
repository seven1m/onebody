$('#attended_at').on 'changeDate', (e) ->
  location.href = '?attended_at=' + encodeURIComponent(this.value)
