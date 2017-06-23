var Header = {};

Header.currentOffset = 0;

Header.initialize = function(){
  $(".drawer-toggle").click(Header.drawerToggle);
  $(".user_logged").click(Header.rightNavToggle);
  $("#search-ic").click(Header.searchToggle);
  $('#empty_space').click(Header.closeDrawers);
  $('.search_bar form').bind('submit', function(){
    $('.search_bar form').reset();
  });

  $('#sign-up-button').click(Header.signUpMenu);
  $('.forgot_pass').click(Header.resetPassMenu);
 
  
  $('.prev_menu').click(Header.prevMenu);
  $('.prev_menu_reset').click(Header.prevMenuReset);

  $("#logout_button").click(Header.logout);

  window.onscroll= function () {
    if($('body').hasClass('home-page')){
      if($(this).scrollTop() < 46){
        $('#header').addClass('home_page');
        $(".circle.item_count").css('background', 'none');
        $('#white_basket').removeAttr('style');
        $('#black_basket').attr('style','display:none');
      }
      else {
        $('#header').removeClass('home_page');
        $(".circle.item_count").css('background', '#006699');
        $('#black_basket').removeAttr('style');
        $('#white_basket').attr('style','display:none');
      }
    }
  }
}

Header.drawerToggle = function(){

  if($('#right_nav').hasClass('slide_left')){
    //close right drawer
    $('#right_nav').removeClass('slide_left');
    $('.right-nav-toggle').removeClass('open');  
    $('#empty_space').removeClass('active');
  }

  if($('#left_nav').hasClass('slide_right')){
    $('#left_nav').removeClass('slide_right');
    $('.drawer-toggle').removeClass('open');
    $('#empty_space').removeClass('active');
  }else{
    $('#left_nav').addClass('slide_right');
    $('.drawer-toggle').addClass('open');
    $('#empty_space').addClass('active');
  }
};

Header.rightNavToggle = function(){
  if($('#left_nav').hasClass('slide_right')){
  //close left drawer
    $('#left_nav').removeClass('slide_right');
    $('.drawer-toggle').removeClass('open');
    $('#empty_space').removeClass('active');
  }

  if($('#right_nav').hasClass('slide_left')){
    //close right drawer
    $('#right_nav').removeClass('slide_left');
    $('.right-nav-toggle').removeClass('open');
    $('#empty_space').removeClass('active');
    Header.clearClose();
  }else{
    $('#right_nav').addClass('slide_left');
    $('.right-nav-toggle').addClass('open');
    $('#empty_space').addClass('active');
  }

  $('#header .search').removeClass('open');
};

Header.searchToggle = function(){

  if($('#right_nav').hasClass('slide_left'))
  {
    $('#right_nav').removeClass('slide_left');
    $('.right-nav-toggle').removeClass('open');  
    $('#empty_space').removeClass('active');
  }
  
  if($('#header .search').hasClass('open'))
    $('#empty_space').removeClass('active');
  else
    $('#empty_space').addClass('active');

  if($('#header .search').hasClass('open'))
    $('#header .search').removeClass('open');
  else{
    $('#header .search').addClass('open');
    $('.search_bar input').focus();

  }

};

Header.closeDrawers = function(){
  if($('#left_nav').hasClass('slide_right'))
    Header.drawerToggle();

  if($('#right_nav').hasClass('slide_left'))
    Header.rightNavToggle();

  if($('#header .search').hasClass('open'))
    $('#header .search').removeClass('open');

  $('#empty_space').removeClass('active');
  Header.clearClose();
};

Header.signUpMenu = function(){
  //$('.landing_menu, .sign_in_menu').addClass('slide_left');
  $('#sign-up-button').parents('.sign_menu').addClass('inactive');
  $('#sign_up_menu').removeClass('inactive');

};

Header.resetPassMenu = function(){
  //$('.landing_menu, .sign_in_menu').addClass('slide_left');
  $('.forgot_pass').parents('.sign_menu').addClass('inactive');
  $('#reset_pass_menu').removeClass('inactive');

};

Header.nextMenu = function(me, menu_tag){

  console.log("nextMenu");
  $(me).parents('.sign_menu').addClass('inactive');
  $(menu_tag).removeClass('inactive');

};

Header.prevMenu = function(){
  //$('.landing_menu, .sign_in_menu').addClass('slide_left');
  $(this).parents('.sign_menu').addClass('inactive');
  $(this).parents('.sign_menu').prev().removeClass('inactive');
};

Header.prevMenuReset = function(){
  //$('.landing_menu, .sign_in_menu').addClass('slide_left');
  $(this).parents('.sign_menu').addClass('inactive');
  $(this).parents('.sign_menu').prev().prev().removeClass('inactive');
};

Header.clearClose = function()
{
  $("#login_menu input[name=email], #login_menu input[name=pass]").val('');
  $("#sign_up_menu input[name=email], #sign_up_menu input[name=nickname], #sign_up_menu input[name=pass], #sign_up_menu input[name=verif_pass]").val('');
  $('.sign_menu').addClass('inactive');
  $("#sign_in_menu").removeClass('inactive');
};

Header.logout = function(){
  
  $.ajax(
  {
    url : "/logout",
    success : function(data) {
      window.location.reload();
    }
  });

};

$(document).ready(function () {
  if($('body').hasClass('home-page')){
    if($(this).scrollTop() < 46){
      $('#header').addClass('home_page');
    }
    else {
      $('#header').removeClass('home_page');
    }
  }
  $('#header .search_bar input').keydown(function(e) {
    console.log("down");
    
    if(e.which === 27) {
      Header.searchToggle();
    }
  });
});