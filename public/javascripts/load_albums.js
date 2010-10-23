albums = null;
function load_tab(id) {
  if(id == 'picture' && !albums) {
    $('#albums_loading').show();
    $.get(ALBUMS_JSON_PATH, null, function(data){
      $('#albums_loading').hide();
      albums = data;
      $.each(albums, function(i, a){
        var option = document.createElement('option');
        option.value = a.album.id;
        option.text = a.album.name;
        try {
          $('#album_id')[0].add(option, null);
        } catch(ex) {
          $('#album_id')[0].add(option);
        }
      })
      var option = document.createElement('option');
      option.value = '!';
      option.text = '[new]';
      try {
        $('#album_id')[0].add(option, null);
      } catch(ex) {
        $('#album_id')[0].add(option);
      }
    }, 'json');
  }
}
