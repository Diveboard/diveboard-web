define(['jquery'], function($){  

  $(document).ready(function(){

    //Sliding menu behaviour
    $("label").click(function(){
      var tmp = $("#slide_panel").width();
      if($('label[for=menu]').hasClass('closed')){
        $('label[for=menu]').toggleClass('closed opened');
        $("#slide_panel").animate({width: 'toggle'});
        $("label").animate({marginLeft: '15rem' });
      } else {
        $('label[for=menu]').toggleClass('opened closed');
        $("#slide_panel").animate({width: 'toggle'});
        $("label").animate({marginLeft: 0});
      }
    });

    //we need to close the menus when clicked outside
    $(window).click(function (e) {
      if(!$(e.target).is('.dropdown input:checkbox')){
        if($('.dropdown input:checkbox').is(':checked')){
          $('.dropdown input:checkbox').prop('checked', false);
        }      
      }

      if(!$(e.target).is('label[for=menu]')){
        if($('label[for=menu]').hasClass('opened')){
          $('label[for=menu]').click()
        }      
      }
      
    })

  })
})