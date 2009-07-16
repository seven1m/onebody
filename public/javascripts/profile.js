albums = null;
function load_tab(id) {
  if(id == 'picture' && !albums) {
    new Ajax.Request(ALBUMS_JSON_PATH, {
      method: 'get',
      onLoading: function(){
        Element.show('albums_loading')
      },
      onSuccess: function(transport){
        Element.hide('albums_loading')
        albums = transport.responseText.evalJSON();
        albums.each(function(a){
          var option = document.createElement('option');
          option.value = a.id;
          option.text = a.name;
          try {
            $('album_id').add(option, null);
          } catch(ex) {
            $('album_id').add(option);
          }
        })
        var option = document.createElement('option');
        option.value = '!';
        option.text = '[new]';
        try {
          $('album_id').add(option, null);
        } catch(ex) {
          $('album_id').add(option);
        }
      }
    });
  }
}
