define(['jquery'], function($){
  var exports = {};

  $(document).ready(function(){
    header = $('.shortcuts_header');
    tmp = header.offset().top;
    con = $('.content_box');
    extra_offset = 100;

    $('.header_degrad').css("height", con.offset().top + extra_offset + (($(document).scrollTop()) / ($(document).height() - $(window).height() )) * ( $(window).height() - con.offset().top - extra_offset));

    $(document).scroll(function(){
      var top = $(this).scrollTop();
      var progress = ($(document).scrollTop()) / ($(document).height() - $(window).height() );
      var res = con.offset().top + extra_offset + progress * ( $(window).height() - con.offset().top - extra_offset);
      $('.header_degrad').css("height", res);   
      
      //sticky header
      if(top > con.position().top)
      {
       header.css("position","fixed");
       header.css("top","0");
       header.css("left","0");
       header.css("width", '100%');
       con.css("padding-top", header.height());
      }
      else{
        header.css("position", "relative");
        header.css("width", "100%");
        con.css("padding-top", 0);
      }
      //Colouring header links depending the scroll position
      $('.about').css("color","inherit");
      $('.dives').css("color","inherit");
      $('.photos').css("color","inherit");
      $('.reviews').css("color","inherit");
      $('.services').css("color","inherit");
      if (top < $('.services_offered').offset().top - 100){
        if (top < $('.shop_reviews').offset().top - 100) {
          if (top < $('.photostream').offset().top - 100) {
            if (top < $('.past_dives').offset().top - 100) {
              $('.about').css("color","red");
            }else {
              $('.dives').css("color","red");
            }
          }else {
            $('.photos').css("color","red");
          }
        }else {
          $('.reviews').css("color","red");
        }
      }else {
        $('.services').css("color","red");
      }
      //sticky floating menu
      if($('.content_box').position().top - $(window).scrollTop() < $('.dropdown input:checkbox').height() + $('.dropdown').position().top){
        // $('.shortcuts_header').append($('.dropdown'));
        if(!$('.shortcuts_header').find('.dropdown').length > 0)
          $('.dropdown').hide().appendTo($('.shortcuts_header')).fadeIn(800);
      } else {
        if(!$('.popup_panel').find('.dropdown').length > 0){
          $('.dropdown').hide().appendTo($('.popup_panel')).fadeIn(800);
        }
      }
    });

    //behaviour of the services expanders
    $(".expander").click(function(){
      h = $(this).parent().find("table").height() + $(this).parent().find(".category_head").height() + $(this).parent().find(".expander").height() ;
      if($(this).parent().hasClass('expanded')){
        $(this).parent().animate({height:0});
        $(this).parent().toggleClass('expanded');
      }
      else if($(this).parent().find('.title').length > 5){
        $(this).parent().animate({height:h});
        $(this).parent().toggleClass('expanded');
      }
      
      
    });

    initialize_editors();
  });

  function initialize_editors()
  {
    //modal text editor used throughout diveboard to edit texts stored in the wiki database
    elRTE.prototype.options.panels.diveboard_edit_panel1 = [
      'formatblock', 'removeformat'
    ];
    elRTE.prototype.options.panels.diveboard_edit_panel2 = [
      'bold', 'italic', 'underline', 'justifyleft', 'justifyright',
      'justifycenter', 'justifyfull',
       'insertorderedlist', 'insertunorderedlist',
      'link', 'image', 'flash'//, 'stopfloat'
    ];
    elRTE.prototype.options.toolbars.diveboardtoolbar = ['diveboard_edit_panel1', 'undoredo', 'alignment', 'diveboard_edit_panel2'];

    var opts = {
            cssClass : 'el-rte',
            height   : 100,
            toolbar  : 'diveboardtoolbar',
            cssfiles : ['../mod/elrte/css/elrte-inner.css']
          }

    $('#text_editor').elrte(opts);
  }

  $(window).on("hashchange", function () {
    window.scrollTo(window.scrollX, window.scrollY - 100);
  });
  return(exports);
})
