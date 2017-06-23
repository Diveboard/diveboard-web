var LightFrame = {};

LightFrame.swipe = null;
LightFrame.loaded = false;
LightFrame.pictureList = [];
LightFrame.initializedTo = -1;
LightFrame.pictureSelected = -1;
LightFrame.currentThread = null;
LightFrame.pictureIdHash = [];
LightFrame.empty = true;
/*LightFrame.init = function(id)
{
  $('#light_frame .close_button').tclick(LightFrame.close);
  $(document).keydown(function(e)
    {
      switch (e.which)
      {
        case 27:
          LightFrame.close();
        break ;
        default :
        return ;
      }
      e.preventDefault();
    });
  $(window).resize(LightFrame.resizeFrame);
  LightFrame.swipe = $('.picture_container').swiper({
    mode:'horizontal',
    loop: false,
    slidesPerView: 'auto'
  });
  LightFrame.swipe.wrapperTransitionEnd(LightFrame.slideEnd,true);
  LightFrame.resizeFrame();
  LightFrame.swipe.enableKeyboardControl();
  LightFrame.swipe.enableMousewheelControl();
  $('#dq_comments').tclick(LightFrame.toggleComments);
};*/

LightFrame.init = function(id_list)
{
  $('#light_frame .close_button').click(LightFrame.close);
  $(document).keydown(function(e)
    {
      switch (e.which)
      {
        case 27:
          LightFrame.close();
        break ;
        default :
        return ;
      }
      e.preventDefault();
    });
  $(window).resize(LightFrame.resizeFrame);
  $('#dq_comments').click(LightFrame.toggleComments);
  $('#fish_button').click(LightFrame.showFish);
  $('#overlay').click(LightFrame.closeAllPanels);
  LightFrame.addPictures(id_list);
  /*LightFrame.swipe = $('.picture_container').swiper({
    mode:'horizontal',
    loop: false,
    slidesPerView: 'auto'
  });*/
  LightFrame.swipe = new Swiper('.picture_container', {
    mode:'horizontal',
    loop: false,
    slidesPerView: 'auto'
  });
  LightFrame.swipe.wrapperTransitionEnd(LightFrame.slideEnd,true);
  LightFrame.resizeFrame();
  LightFrame.swipe.enableKeyboardControl();
  LightFrame.swipe.enableMousewheelControl();
};

LightFrame.resizeFrame = function()
{
  $('.swiper-slide').css('width', window.innerWidth + 'px');
  LightFrame.swipe.reInit();
  //LightFrame.swipe.resizeFix();
};

LightFrame.displayLive = function(selected_picture)
{
  LightFrame.pictureSelected = selected_picture
  var index = LightFrame.getPictureIndexById(selected_picture);
  if (LightFrame.loaded == false || index == -1)
  {
    $('#light_frame .light_loading').css('padding-top', ((window.innerHeight / 2) - 47) + 'px');
    $('#light_frame .light_loading').css('display', 'block');
    //$('#light_frame .picture_container').css('display', 'none');
    //$('#light_frame .info').css('display', 'none');
  }
  else
  {
    $('#light_frame .light_loading').css('display', 'none');
    //$('#light_frame .picture_container').css('display', 'block');
    //$('#light_frame .info').css('display', 'block'); 
  }
  //$('.main_picture').attr('src', picture_list[0]);
  LightFrame.swipe.reInit();
  //LightFrame.slideEnd();
  $('#light_frame').css('display', 'block');
  $('body').css('overflow', 'hidden');
  if (index == -1)
    return ;
  if (index == 0)
  {
    LightFrame.swipe.swipeTo(1, 0, false);
    LightFrame.swipe.params.speed = 0;
    LightFrame.swipe.swipePrev();
    LightFrame.swipe.params.speed = 300;
  }
  else
    LightFrame.swipe.swipeTo(index, 0, false);    

  LightFrame.slideEnd();
  LightFrame.resizeFrame();
  disable_scroll();
};

LightFrame.getPictureIndexBySrc = function(selected_picture)
{
  var img_list = $('.main_picture');
  var i = 0;
  var length = img_list.length;

  while (i < length)
  {
    if ($(img_list[i]).attr('src') == selected_picture)
      break ;
    i++;
  }
  if (i >= length)
    return (-1);
  return (i);
};

LightFrame.getPictureIndexById = function(picture_id)
{
  var i = 0;
  var length = LightFrame.pictureList.length;

  while (i < length)
  {
    if (LightFrame.pictureList[i].id == picture_id)
      break ;
    i++;
  }
  if (i >= length)
    return (-1);
  return (i);
};

LightFrame.addPictures = function(id_list)
{
  $.ajax({
    type: 'POST',
    url: '/api/lightframe_data',
    data: {pic_ids: id_list},
    dataType: "json",

  }).success(function (data){
    if (data.success == true)
    {
      var i = 0;
      var length = data.data.length;
      while (i < length)
      {
        if (LightFrame.pictureIdHash[data.data[i].id] == undefined)
        {
          if(data.player_big!=null){
              data.data[i].player_big=data.player_big;
          }
          LightFrame.pictureIdHash[data.data[i].id] = true;
          LightFrame.pictureList.push(data.data[i]);
        }
        i++;
      }
      LightFrame.append();
    }
  });
}

LightFrame.append = function()
{
  //var elems = $(elem_id);
  //var i = $('.main_picture').length;
  //var length = elems.length;
  var length = LightFrame.pictureList.length;
  var append_str = '';
  if (LightFrame.initializedTo == -1)
    LightFrame.initializedTo = 0

  while (LightFrame.initializedTo < length)
  {
    //var data = $.parseJSON($(elems[i]).html());
    var data = LightFrame.pictureList[LightFrame.initializedTo];
    if(data.player_big!=null){
      append_str += '<div class="swiper-slide"><span class="helper"></span>' + data.player_big + '</div>';
    }else{
      append_str += '<div class="swiper-slide"><span class="helper"></span><img class="main_picture" src="' + data.large + '" alt="" /></div>';

    }
    LightFrame.initializedTo++;
  }
    if(LightFrame.empty)
    $('.swiper-wrapper').empty();

  $('.swiper-wrapper').append(append_str);
  if (LightFrame.loaded == false)
  {
    LightFrame.loaded = true;
    //$('.picture_container').css('display', 'block');
   // $('.info').css('display', 'block');
    //$('.light_loading').css('display', 'none');
    //LightFrame.displayLive(LightFrame.pictureSelected);
  }
  //$('.picture_container').css('display', 'block');
  //$('.info').css('display', 'block');
  $('.light_loading').css('display', 'none');
  if (LightFrame.pictureSelected != -1)
  {
    LightFrame.swipe.reInit();
    LightFrame.resizeFrame();
    var index = LightFrame.getPictureIndexById(LightFrame.pictureSelected);
    if (index == 0)
    {
      LightFrame.swipe.swipeTo(1, 0, false);
      LightFrame.swipe.params.speed = 0;
      LightFrame.swipe.swipePrev();
      LightFrame.swipe.params.speed = 300;
    }
    else
      LightFrame.swipe.swipeTo(index, 0, false);
    
    LightFrame.slideEnd();
    LightFrame.resizeFrame();
    disable_scroll();
    return ;
  }
  LightFrame.swipe.reInit();
  LightFrame.resizeFrame();
};

LightFrame.close = function()
{
  LightFrame.pictureSelected = -1;
  enable_scroll();
  LightFrame.closeAllPanels();
  $('#light_frame').css('display', 'none');
  $('body').css('overflow', 'auto');
  $('.comments').removeClass('active');
};

LightFrame.slideEnd = function()
{
  if (LightFrame.loaded == false)
    return ;
  LightFrame.closeAllPanels();
  var slide = LightFrame.swipe.getSlide(LightFrame.swipe.activeIndex);
  var idx = LightFrame.swipe.activeIndex;
  //console.log($(slide).find('.data').html());
  //var data = $.parseJSON($(slide).find('.data').html());
  $('#title').html(LightFrame.pictureList[idx].title);
  $('#location').html(LightFrame.pictureList[idx].location);
  $('#date_camera').html(LightFrame.pictureList[idx].date_camera);
  $('#user_pic').attr('src', LightFrame.pictureList[idx].user_pic);
  $('#user_pic').wrap($('<a>',{href: "/"+LightFrame.pictureList[idx].fullpermalink.split("/")[3]}));
  $('#user_name').html(LightFrame.pictureList[idx].user_name);
  $('#user_name').attr('href', "/"+LightFrame.pictureList[idx].fullpermalink.split("/")[3]);
  if ($('#follow_link') != undefined)
  {
    if (follow_ids.indexOf(LightFrame.pictureList[idx].user_id) != -1)
      $('#follow_link').html('( <a href="javascript:void(0)" onclick="LightFrame.followUser()"><img class="check_icon" src="/img/gallery/check_icon_full.png" alt="" /> Unfollow</a>)');
    else
      $('#follow_link').html('( <a href="javascript:void(0)" onclick="LightFrame.followUser()"><img class="check_icon" src="/img/gallery/check_icon.png" alt="" /> Follow me</a>)');
  }
  $('#qualification').html(LightFrame.pictureList[idx].qualification);
  $('#former_loc').html(LightFrame.pictureList[idx].former_loc);
  LightFrame.pictureSelected = idx;
  $('#comment_count').html('(...)');
  $('#species_count').html('(' + LightFrame.pictureList[LightFrame.swipe.activeIndex].species.length + ')');
  update_disqus_count(LightFrame.swipe.activeIndex);
};

LightFrame.toggleComments = function()
{
  var idx = LightFrame.swipe.activeIndex;

  if($('.comments').hasClass('active'))
    $('.comments').removeClass('active');
  else{
    $('.comments').addClass('active');
    $('#overlay').css('display', 'block');
    //var slide = LightFrame.swipe.getSlide(LightFrame.swipe.activeIndex);
    //var data = $.parseJSON($(slide).find('.data').html());
    if (LightFrame.currentThread == null || LightFrame.currentThread != LightFrame.pictureList[idx].thread_identifier)
    {
      reset_dsq(LightFrame.pictureList[idx].thread_identifier);
      LightFrame.currentThread = LightFrame.pictureList[idx].thread_identifier;
    }
  }
};

LightFrame.showFish = function()
{
  var idx = LightFrame.swipe.activeIndex;

  $('.fish').addClass('active');
  $('#overlay').css('display', 'block');
  
  var idx = LightFrame.swipe.activeIndex;
  if (LightFrame.pictureList[idx].species.length == 0)
  {
    //var fish_list = "<ul><li>No fish have been identified on this picture yet</li></ul>";
    var fish_list = "<p>No fish have been identified on this picture yet</p>";
  }
  else
  {
    var fish_list = "<ul>";
    $.each(LightFrame.pictureList[idx].species, function(index,value)
    {
      //fish_list += "<li><a href='javascript:void(0)' picture='" + idx + "' species='" + index + "'>";
      fish_list += "<li><h2>";
      if (value.cname != "" && value.cname != null)
        fish_list += value.cname + " (" + value.sname + ")</h2>";
      else
        fish_list += value.sname + "</h2>";
      if (value.description != "" && value.description != null)
      {
        fish_list += "<p class='description'>" + value.description + "</p><p class='source_species'>Source: <a href='" + value.url + "'>EOL.org</a></p>";
        if (index < LightFrame.pictureList[idx].species.length - 1)
          fish_list += '<br>';
      }
      else
        fish_list += "<p>No available description for this species. Feel free to submit one on <a href='" + value.url + "'>EOL.org</a></p>";
      fish_list += "</li>";
    });
    fish_list += "</ul>";
  }
  console.log(fish_list);
  $(".fish .container").html(fish_list);
};

function findIndex(elem, to_find)
{
  var i = 0;
  var len = elem.length;

  while (i < len)
  {
    if (elem[i] == to_find)
      return (i);
    i++;
  }
  return (-1);
}

LightFrame.followUser = function()
{
  var idx = LightFrame.swipe.activeIndex;

  var request = {};
  request['user_id'] = LightFrame.pictureList[idx].user_id;
  var id_idx = findIndex(follow_ids, LightFrame.pictureList[idx].user_id);
  if (id_idx != -1)
  {
    request['do'] = 'remove';
    follow_ids.splice(id_idx, 1);
  }
  else
  {
    request['do'] = 'add';
    follow_ids.push(request['user_id']);
  }
  LightFrame.slideEnd();
  $.ajax({
    url: '/api/user/following',
    datatype: 'json',
    data: request,
    type: 'POST'
  });
};

LightFrame.closeAllPanels = function()
{
  $('.comments').removeClass('active');
  $('.fish').removeClass('active');
  $('#overlay').css('display', 'none');
};

// left: 37, up: 38, right: 39, down: 40,
// spacebar: 32, pageup: 33, pagedown: 34, end: 35, home: 36
var keys = [32, 33, 34, 35, 36, 38, 40];

function preventDefault(e) {
  e = e || window.event;
  if (e.preventDefault)
      e.preventDefault();
  e.returnValue = false;  
}

function keydown(e) {
    for (var i = keys.length; i--;) {
        if (e.keyCode === keys[i]) {
            preventDefault(e);
            return;
        }
    }
}

function wheel(e) {
  preventDefault(e);
}

function disable_scroll() {
  if (window.addEventListener) {
      window.addEventListener('DOMMouseScroll', wheel, false);
  }
  window.onmousewheel = document.onmousewheel = wheel;
  document.onkeydown = keydown;
  $(document).unbind('touchmove', function(e) {
    e.preventDefault();
  });
}

function enable_scroll() {
    if (window.removeEventListener) {
        window.removeEventListener('DOMMouseScroll', wheel, false);
    }
    window.onmousewheel = document.onmousewheel = document.onkeydown = null;  
    $(document).bind('touchmove');
}

function update_disqus_count(idx)
{
  if (LightFrame.pictureList[idx].disqus_count == -1)
  {
    $.ajax({
      type: 'GET',
      url: "https://disqus.com/api/3.0/threads/details.jsonp",
      data: { api_key: disqus_public_key, forum : disqus_shortname, 'thread:ident' : LightFrame.pictureList[idx].thread_identifier },
      cache: false,
      dataType: 'jsonp',
      success: function (result)
      {
        var i = 0;
        var length = LightFrame.pictureList.length;
        var thread_identifier = LightFrame.pictureList[idx].thread_identifier;

        while (i < length)
        {
          if (LightFrame.pictureList[i].thread_identifier == thread_identifier)
            LightFrame.pictureList[i].disqus_count = result.response.posts;
          i++;
        }
        display_disqus_count(idx);
      },
      error: function (result)
      {
        display_disqus_count(idx, true);
      }
    });
  }
  else
    display_disqus_count(idx);
  return ;
}

function display_disqus_count(idx, error)
{
  if (error != null && error == true)
  {
    $('#comment_count').html('(0)');
    return ;
  }
  if (LightFrame.swipe.activeIndex == idx && LightFrame.pictureList[idx].disqus_count != -1)
    $('#comment_count').html('(' + LightFrame.pictureList[idx].disqus_count + ')');
}