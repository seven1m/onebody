$(function(){
  $('input[placeholder]').focus(function(){
    var i = $(this);
    var p = i.attr('placeholder');
    if(i.val() == p) i.val('');
  }).blur(function(){
    var i = $(this);
    var p = i.attr('placeholder');
    if(i.val() == '') i.val(p);
  }).trigger('blur');
});
