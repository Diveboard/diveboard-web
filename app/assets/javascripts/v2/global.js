//touch click helper
(function ($) {
  $.fn.tclick = function (onclick) {
    this.bind("touchstart", function (e) { onclick.call(this, e); e.stopPropagation(); e.preventDefault(); });
    this.bind("click", function (e) { onclick.call(this, e); }); //substitute mousedown event for exact same result as touchstart 
    return this;
  };
})(jQuery);


function diveboard_ask_join(initialising, opts){
    var time= $.cookie("signup_delay") || 0 ; ;
    time = Number(time);
    var delay = 1000;
    var nb_calls = $.cookie("signup_click_count") || 0 ;
    nb_calls = Number(nb_calls);
    var params={
      show_popup: function(){ diveboardAccount.start({form: $("#dialog-login-join")}); },
      nb_calls: 3
    };
    for(var key in opts) {
      if(!opts[key]) {
        delete opts[key];
      }
    }   
    if (opts)
      $.extend(params, opts);

    var ARRcookies=document.cookie.split(";");

    if (initialising){
      nb_calls += 1;
      $.cookie("signup_click_count", nb_calls, { expires : 1 });
    } else {
      time += delay;
      $.cookie("signup_delay", time, { expires : 1 });
    }

    //If the visitor has been here long enough, prompt him to register, else keep waiting
    if (nb_calls >  params.nb_calls || time > 15000){
      setTimeout(function(){
      	$.cookie("signup_click_count", 0, { expires : 1 });
        $.cookie("signup_delay", 0, { expires : 1 });
        params.show_popup();

        ga('send', {
          'hitType': 'event',
          'eventCategory': 'login',
          'eventAction': 'prompt_join',
          'nonInteraction': true
        });
      });

    } else {
      setTimeout(function(){ diveboard_ask_join(false, opts); }, delay);
    }
};