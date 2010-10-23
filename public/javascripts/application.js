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
