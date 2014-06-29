jQuery.fn.center = function() {
  this.css("position", "absolute");
  this.css("top", Math.max(0, (($(window).height() - $(this).outerHeight()) / 2) +
    $(window).scrollTop()) - 30 + "px");
  this.css("left", Math.max(0, (($(window).width() - $(this).outerWidth()) / 2) +
    $(window).scrollLeft()) + "px");
  return this;
}
