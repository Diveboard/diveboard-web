function logbook_ready(){
  $('.autoclear').autoclear();

  //load tooltips
  $('.tooltiped').qtip({
      style: {
        tip: { corner: true },
        classes: "ui-tooltip-diveboard"
      },
      position: {
        at: "bottom center",
        my: "top right"
      }
    });

  /* Enable scroll pane navigation */
  $(".scroll-pane .dive_item").click(function(ev){

    if( $.browser.msie && $.browser.version < 9.0){
      //do nothing, just follow the link.
    }else{
     //we're ie>8
     ev.preventDefault();
     showDive($(this).attr('id').substr(4));
   }
  });

  profile_img = $("#mini_profile_image_src");
  if (profile_img.width() > profile_img.height())
    profile_img.width(99);
  else
    profile_img.height(99);


  register_FB_events();

  initialize_follow_links();

  $("li.trip_name .folding_icon").click(function(){
    var arrow = $(this);
    arrow.toggleClass('folded');
    if (arrow.hasClass('folded')) {
      $( $(this).attr('data-trip-class')).slideUp(200);
      arrow.html("]");
    } else {
      $( $(this).attr('data-trip-class')).slideDown(200);
      arrow.html("[");
    }
  });

  try {
    if (content_initialize) content_initialize();
  } catch(e){}
}




function register_FB_events(){
  if (!G_events_registered) {
    if (typeof(FB) =="undefined"){
      setTimeout(register_FB_events, 500);
      return;
    }
    try {
      FB.Event.subscribe('comment.create', notify_event('comment.create'));
      FB.Event.subscribe('comment.remove', notify_event('comment.remove'));
      FB.Event.subscribe('edge.create', notify_event('edge.create'));
      FB.Event.subscribe('edge.remove', notify_event('edge.remove'));
      G_events_registered = true;
    } catch(e){
      console.log("Could not register FB events "+ e.message);
    }
  }
}

function notify_disqus_event(ev_type, disqus_msg) {
  $.ajax({
    url: '/api/notify_event',
    dataType: 'json',
    data: ({
      dive_id: G_dive_id,
      disqus_message: disqus_msg, 
      event: ev_type,
      'authenticity_token': auth_token
      }),
    type: "POST"
  });
}

function notify_event(ev_type) {
  return( function(resp) {
    var data = {
          dive_id: G_dive_id,
          event: ev_type,
          'authenticity_token': auth_token
          };
    if ($("#lightbox").is(":visible")){
      try{
        data.picture_id = dive_pictures_data[lightbox_photoswipe.currentIndex].id;
      }catch(e){

      }
    }else{

    }
      $.ajax({
        url: '/api/notify_event',
        dataType: 'json',
        data: data,
        type: "POST"
        });
  } );
}

function notify_google_like(data){
  var ev_type = "";
  var data = {
          dive_id: G_dive_id,
          event: ev_type,
          'authenticity_token': auth_token
          };
  if (data.state == "on"){
    data.ev_type = "google_like";}
  else{
    data,ev_type = "google_unlike";}
    if ($("#lightbox").is(":visible")){
      try{
        data.picture_id = dive_pictures_data[lightbox_photoswipe.currentIndex].id;
      }catch(e){
      }
    }else{
    }
  $.ajax({
        url: '/api/notify_event',
        dataType: 'json',
        data: data,
        type: "POST"
        });

}


function showDive(divenumber, update) {
  nuke_lightbox(); // nuking the lightbox
  window.onbeforeunload = null; // enable navigation again
  if(update && update == true)
    var url = G_owner_api.permalink+"/partial/"+divenumber+"?updated=true";
  else
    var url = G_owner_api.permalink+"/partial/"+divenumber;
  //masks the dive file and wait
  try {
    hide_wizard();
  } catch(e) {}
  if (divenumber != "new") wizard_bulk = false;
  diveboard.mask_file(true);
  //change pointer
  $(".scroll_active_item").removeClass('scroll_active_item');
  $("#dive"+divenumber).addClass('scroll_active_item');
    $("#main_content_area").load(url, function(responseText, textStatus, req) {
      //alert(responseText);
    //unmask the dive

    if(responseText[0]=="{" && JSON.parse(responseText)['goto']){
    showDive(JSON.parse(responseText)['goto']);
    }
    else{
      $(".noshowhome").show();
      $(".showhome").hide();
      $("#sidebar .shop_see_profile").show();
      diveboard.unmask_file({'z-index': '9000'});
      try {
        if (content_initialize) content_initialize();
      } catch(e){}
      //AShow Permalink
      //IF html5
      try{
        if(window.history.pushState) window.history.pushState("","",G_dive_api.permalink);
      }catch(e){}


      //Re-launch comments and like on the page
      if(dive_updated){
        //we're showing dive after an update
        //and it was done in ajax
        $(".tab_link").removeClass("active");
        $("#tab_share_link").addClass("active");
        dive_updated=false;
      }
      FB.XFBML.parse(); //reparse the fbml
      $(".header_user_page").text(I18n.t(["js","logbook","LOGBOOK"]));
          try {
          jsPaneAPI.scrollToElement($("#dive"+divenumber),true,false)
          jsPaneAPI.scrollByY(-60);
          } catch(e) {}
      }
    });
}
