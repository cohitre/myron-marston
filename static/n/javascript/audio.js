(function($) {
  $('.audio-list li a').click(function(e) {
    var $this = $(this);
    $('audio').each(function(i, element) {
      element.pause();
    });

    $this.siblings('audio')[0].play();
  });
})($);

