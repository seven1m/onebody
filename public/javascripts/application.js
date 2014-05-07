function observeFields(func, frequency, fields) {
  observeFieldsValueMap = window.observeFieldsValueMap || {};
  $.each(fields, function(index, field){
    observeFieldsValueMap[field] = $('#'+field).val();
  });
  var observer = function() {
    var changed = false;
    for(var f in observeFieldsValueMap) {
      var currentValue = $('#'+f).val();
      if(observeFieldsValueMap[f] != currentValue) {
        observeFieldsValueMap[f] = currentValue;
        changed = true;
      }
    }
    if(changed) func(f);
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

function shareSomething(hash) {
  $('#share').dialog('open');
  $('#share-something').hide();
  $('#map-container').hide();
  $('#group-details').hide();
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

function setupMenu(selector, contentSelector) {
  $(selector).qtip({
    content: $(contentSelector).html(),
    show: {
      delay: 500,
      when: {
        event: 'mouseover'
      },
      effect: {
        type: 'slide'
      }
    },
    hide: {
      delay: 1000,
      fixed: true,
      when: {
        event: 'mouseout'
      }
    },
    style: {
      name: 'light',
      tip: navigator.userAgent.match(/mobile/i) ? 'topLeft' : 'topMiddle'
    },
    position: {
      corner: {
        target: 'bottomMiddle',
        tooltip: navigator.userAgent.match(/mobile/i) ? 'topLeft' : 'topMiddle'
      }
    }
  });
}

function setupMenus() {
  if($('#home-tab-menu').length == 1) {
    setupMenu('#home-tab', '#home-tab-menu');
  }
  if($('#profile-tab-menu').length == 1) {
    setupMenu('#profile-tab', '#profile-tab-menu');
  }
  if($('#group-tab-menu').length == 1) {
    setupMenu('#group-tab', '#group-tab-menu');
  }
}

$(setupMenus);
