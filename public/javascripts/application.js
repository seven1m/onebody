function observeFields(func, frequency, fields) {
  observeFieldsValueMap = window.observeFieldsValueMap || {};
  $.each(fields, function(index, field){
    observeFieldsValueMap[field] = $('#'+field).val();
  });
  var observer = function() {
    for(var f in observeFieldsValueMap) {
      var currentValue = $('#'+f).val();
      if(observeFieldsValueMap[f] != currentValue) {
        observeFieldsValueMap[f] = currentValue;
        func(f);
        return;
      }
    }
  };
  setInterval(observer, frequency);
};

function custom_select_val(select_elm, prompt_text){
  if(val = prompt(prompt_text, '')) {
    var option = $('<option/>');
    option.val(val);
    option.html(val);
    option.attr('selected', true);
    option.appendTo(select_elm);
    return true;
  } else {
    return false;
  }
};

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

function shareSomething(hash) {
  $('#share').show();
  $('#share-something').hide();
  $('#map-container').hide();
  $('#group-details').hide();
  location.hash = hash || 'note';
}

$('#share_picture_form').live('submit', function(){
  if($('#album_id').val() == '!') {
    return custom_select_val($('#album_id'), $('#share_picture_form').attr('data-album-prompt'));
  }
});

if(location.hash != '') {
  window.after_tab_setup = function() {
    shareSomething(location.hash.replace(/#/, ''));
  };
}
