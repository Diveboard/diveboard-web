$(document).ready(function()
{
  $(window).scroll(function (event) {
    if($('.destinations_tabs') != null){
      scrollingDestinations();
    }
    else{
      scrollingShops();

    }
    if($(window).scrollTop() > ($('.content #cover_pic').height() )){
      $('#header').removeClass('sticky_header');
      $('#tabs').addClass('sticky_header');
      $('#tab_list').addClass('sticky_header');
    }
    else{
      $('#header').addClass('sticky_header');
      $('#tabs').removeClass('sticky_header');
      $('#tab_list').removeClass('sticky_header');
      Header.closeDrawers();
    }
  });

  $('#tabs a.page-link').on('click',function (e) {
    var target = $(this).attr('scroll');
    /*if($('.slides').length <= 0)
    {
      e.preventDefault();
      scrollTo(target);
    }
    else
    {
      $('.section').removeClass('section-active');
      $(target).addClass('section-active');
      setActive($(this).find('.tab'));
    }*/
    e.preventDefault();
    scrollTo(target);
  });

  $('#tab_list select').on('change', function()
    {
      scrollTo('#' + $(this).val());
    });

});

function scrollingDestinations(){
    try{
          if(($(window).scrollTop() + 70) > $('#destination_shops').offset().top){
            $('.active').first().removeClass('active');
            $('#tab_shops').first().addClass('active');
          }
          else if(($(window).scrollTop() + 70) > $('#destination_spots').offset().top){
            $('.active').first().removeClass('active');
            $('#tab_spots').first().addClass('active');
          }
          else{
            $('.active').first().removeClass('active');
            $('#tab_infos').first().addClass('active');
          }
          if($('#area').length>0){
              if(($(window).scrollTop() + 70) > $('#area').offset().top){
              $('.active').first().removeClass('active');
              $('#tab_areas').addClass('active');
            }
          }
        }catch(e){

        }
}
function scrollingShops(){
  if($('.slides').length <= 0)
  {
    //little offset of 50px
    if(document.getElementById('area') != null && $(window).scrollTop() + 50 > $('#area').offset().top)
    {
      setActive($('#tabs').children()[6].children);
      $('#tab_list select').val('area');
    }
    else if(document.getElementById('faq') != null && $(window).scrollTop() + 50 > $('#faq').offset().top)
    {
      setActive($('#tabs').children()[5].children);
      $('#tab_list select').val('faq');
    }
    else if(document.getElementById('shop_reviews') != null && $(window).scrollTop() + 50 > $('#shop_reviews').offset().top)
    {
      setActive($('#tabs').children()[4].children);
      $('#tab_list select').val('shop_reviews');
    }
    else if(document.getElementById('spots') != null && $(window).scrollTop() + 50 > $('#spots').offset().top)
    {
      setActive($('#tabs').children()[3].children);
      $('#tab_list select').val('spots');
    }
    else if(document.getElementById('services') != null && $(window).scrollTop() + 50 > $('#services').offset().top)
    {
      setActive($('#tabs').children()[2].children);
      $('#tab_list select').val('services');
    }
    else if(document.getElementById('gallery') != null && $(window).scrollTop() + 50 > $('#gallery').offset().top)
    {
      setActive($('#tabs').children()[1].children);
      $('#tab_list select').val('gallery');
    }
    else
    {
      if($('#tabs').length!=0){
        setActive($('#tabs').children()[0].children);
        $('#tab_list select').val('shop_info');
      }
    }
  }
  else
  {
    if(document.getElementById('marketing_widget_edit') != null && $(window).scrollTop() + 50 > $('#marketing_widget_edit').offset().top)
      setActive($('#tabs').children()[5].children);
    else if(document.getElementById('cares_edit') != null && $(window).scrollTop() + 50 > $('#cares_edit').offset().top)
      setActive($('#tabs').children()[4].children);
    else if(document.getElementById('faq_edit') != null && $(window).scrollTop() + 50 > $('#faq_edit').offset().top)
      setActive($('#tabs').children()[3].children);
    else if(document.getElementById('services_edit') != null && $(window).scrollTop() + 50 > $('#services_edit').offset().top)
      setActive($('#tabs').children()[2].children);
    else if(document.getElementById('pictures_edit') != null && $(window).scrollTop() + 50 > $('#pictures_edit').offset().top)
      setActive($('#tabs').children()[1].children);
    else
      setActive($('#tabs').children()[0].children);
  }
};

function setActive(tag){
  $('#tabs').children().children().removeClass('active');
  $(tag).addClass('active');
};

function scrollTo(id){
  try{
    var offset = 90;
    if($("#tabs").hasClass('sticky_header'))
      offset = 45;
    
    $('html, body').animate({
        scrollTop: $(id).offset().top - offset
    }, 300);
  }catch(err) {

  }
};

function slideLeft(tag)
{
  $(tag).addClass('slide-left');
};

function slideRight(tag)
{
  $(tag).addClass('slide-right');
};

function fireFollow()
{
  var following = $('#tabs .button_follow').attr('following');
  var request = {};
  request['shop_id'] = $('#tabs .button_follow').attr('shop_id');
  var curr_count = $('.wrapper_follow .count_follow .count').html();

  if (following == "true")
  {
    request['do'] = 'remove';
    curr_count = parseInt(curr_count) - 1;
    $('#tabs .button_follow p').html('Follow');
    $('#tabs .button_follow').attr('following', false);
  }
  else
  {
    request['do'] = 'add';
    curr_count = parseInt(curr_count) + 1;
    $('#tabs .button_follow p').html('Unfollow');
    $('#tabs .button_follow').attr('following', true);
  }
  $('.wrapper_follow .count_follow .count').html(curr_count);

  $.ajax({
    url: '/api/user/following',
    datatype: 'json',
    data: request,
    type: 'POST'
  });
};


function treasureHunt(){
  var action = Math.floor(Math.random()*3+1);
  if(action==1){
    var x = Math.floor(Math.random()*1000+100);
    var y = Math.floor(Math.random()*1000+100);
    $('body').append("<div><img id=\"treasure_hunt\" src="+ window.location.origin+"/img/ic_movescount.png style=\" position:absolute; top:"+x+"px; left:"+y+"px; opacity:0.4;\" width=20px; height=20px;></div>");
    var finded_modal = new LightModal('findedTreasureModal');
    $("#treasure_hunt").click(function(){
      request={};
      request['campaign_name']="Movescount_1"
      request['object_type']= "shop";
      request['object_id']= $('#tabs .button_follow').attr('shop_id');
      $.ajax({
        url: "/api/v2/treasurehunt",
        data: request,
        type: "POST",
        dataType: "json",
        success: function(data) {
          //$('body').append("<div id=\"dialog\" title=\"Well Done\"><p>Well Done. You have found one treasure. Your total is : "+ data['count'] + "</p></div>");
          //$( "#dialog").position({my: "center",at: "center",of:window});
          //$( "#dialog" ).dialog();   
          //diveboard.notify("Well Done. You have found one treasure. Your total is : "+ data['count'],function(){});
          $("#findedTreasureModal .title").html(I18n.t(["js","header","Well Done"]));
          $("#findedTreasureModal .modal_body").html(I18n.t(["js","header","You found one treasure! Your total is : "])+ data['count']);
          finded_modal.display();
          $('#treasure_hunt').hide();     
          console.log(data);
        }
      });
    });
  }
}