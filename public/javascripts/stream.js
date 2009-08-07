$('stream-display-options').style.display = 'block';

function enable_stream_item_type(type, enable) {
  document.cookie = 'stream_' + type + '=' + (enable ? 'true' : 'false');
  update_stream_display();
}

function update_stream_display() {
  $$('.stream-item').each(function(e){e.show()})
  document.cookie.split('; ').each(function(type){
    if(type.match(/^stream_/)) {
      var enabled = type.split('=')[1] == 'true';
      var type = type.split('=')[0];
      var imgs = $$("#enable-" + type + " img");
      if(imgs.length > 0) {
        imgs[0].writeAttribute('src', enabled ? '/images/checkmark.png' : '/images/remove.gif');
        $$('.' + type).each(function(e){ if(!enabled) Element.hide(e) });
      }
    }
  })
}

update_stream_display();

if(location.hash != '') {
  Element.show('share');
  Element.hide('share-something');
}

