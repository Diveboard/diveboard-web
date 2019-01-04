var G_lightbox_bindings_set = false;
var lightbox_data = new Object();
lightbox_data["lightbox_bindings"] = false;
lightbox_data["lightbox_picker_page"] = 0;
lightbox_data["lightbox_has_scroller"] = false;
lightbox_data["lightbox_scroll_controls_width"] = 80;
lightbox_data["like_rendered"] = false;
lightbox_data["comments_rendered"] = false;
lightbox_data["video_coords"] = [0,0,0,0];
lightbox_data["video_rendered"] = false;
lightbox_data["video_holder"] = "";
lightbox_data["list_css_offset"]=function(){
  try{
    var list_offset = Number($(".lightbox_pic_list ul").attr("data-transform").match(/\-*[0-9]+/));
  }catch(e){
    var list_offset = 0;
    }
    return -list_offset;
}
lightbox_data["list_drag_offset"]=function(){
  try{
    var drag_offset = Number($("#lightbox_bottom_controls .lightbox_pic_list ul").css("left").match(/\-*[0-9]+/));
  }catch(e){
    var drag_offset = 0;
  }
  return -drag_offset
}
lightbox_data["list_offset"]=function(){
  //calculates offset combining css transforms and list position
  return this.list_css_offset()+this.list_drag_offset();
}
lightbox_data["max_offset"] = function(){
  try{
    //return (lightbox_data.total_number_pages-1)*lightbox_data.images_per_line*45+($("#lightbox_bottom_controls .lightbox_pic_list li").length%lightbox_data.images_per_line)*45;
    return lightbox_data.total_number_pages*lightbox_data.images_per_line*45
  }catch(e){
    return $("#lightbox_bottom_controls .lightbox_pic_list ul").width();
  }
}

function open_lightbox(id){
  init_lightbox_bindings();

  $("#lightbox_bottom_controls .lightbox_pic_list li").removeClass("selected");
  $("#lightbox").show();
  $("#lightbox_controls").show();
  lightbox_data["like_rendered"] = false;
  lightbox_data["comments_rendered"] = false;
  diveboard.lock_scroll(0,0);
  if(typeof(lightbox_photoswipe) == "undefined")
    {
      setup_lightbox(dive_pictures_data);
      lightbox_photoswipe.show(id);
      init_picture_picker(dive_pictures_data);
  }else{
    try{lightbox_photoswipe.destroyZoomPanRotate();}catch(e){} // destroy the zoom if exits
    try{lightbox_photoswipe.carousel.show(id);}catch(e){lightbox_photoswipe.show(id);}
  }


  set_zoom_fit();
  resize_lightbox();

  //tracking event for google
  try {
    ga('send', {
      'hitType': 'event',          // Required.
      'eventCategory': 'interaction',   // Required.
      'eventAction': 'lightframe_open',      // Required.
      'nonInteraction': false
    });
  }catch(e){
    console.log(e);
  }
}


// Diveboar's lightbox functions
function setup_lightbox(pictures_array){

  nuke_lightbox();
  $("#lightbox_zoom").addClass("lightbox_zoom_fit").removeClass("lightbox_zoom_fs");
  show_controls();

  lightbox_photoswipe = window.Code.PhotoSwipe.attach(pictures_array, {
    enableUIWebViewRepositionTimeout: true,
    minUserZoom: 1,
    target: window.document.querySelectorAll('#lightbox')[0],
    zIndex: 15100,
    imageScaleMethod: "fit",
    captionAndToolbarShowEmptyCaptions: false,
    preventSlideshow: true,
    allowUserZoom: true,
    captionAndToolbarHide: true,
    getToolbar: function(){return("");},
    getImageSource: function(el){
          return el.image_large;
    },
    getImageCaption: function(el){return("");},
    getImageMetaData: function(el){return("");}
  });
  $(lightbox_photoswipe).bind(window.Code.PhotoSwipe.EventTypes.onDisplayImage, lightbox_notify_image_change);
  $(lightbox_photoswipe).bind(window.Code.PhotoSwipe.EventTypes.onBeforeHide, hide_lightbox);
  /*
	 * Function: next
	 */
	 lightbox_photoswipe.next = function(){		
  		if (this.isZoomActive()){
  		  //kill zoom
  			lightbox_photoswipe.destroyZoomPanRotate();
  		}
		
  		if (!window.Code.Util.isNothing(this.carousel)){
  			this.carousel.next();
  		}
    }


}

function nuke_lightbox(){
  //we go nuclear on poor lightbox
  //move_lightbox_picker_topage(0); // reposition the pictures at statrt
  if ($("#lightbox").children().length == 0)
    return;
  else{
    try{
      $("#lightbox_bottom_controls .lightbox_pic_list ul").css("left","0px");
      $(".lightbox_pic_list ul").animate({translateX: 0+'px'});
      $("#lightbox_zoom").addClass("lightbox_zoom_fit").removeClass("lightbox_zoom_fs");

      $("#lightbox").empty();
      //Ensure mega cleanup ... sometimes detatch does not clean up well enough :)
      $.each(window.Code.PhotoSwipe.instances, function(index, value){window.Code.PhotoSwipe.detatch(value);})
    	$.each(window.Code.PhotoSwipe.instances, function(index, value){window.Code.PhotoSwipe.disposeInstance(value);})
    	window.Code.PhotoSwipe.activeInstances = [];
      delete lightbox_photoswipe;
      //end of mega_cleanup
    }catch(err){
      console.log("error nuking lightbox: "+err.message);
    }
  }
	
}

function lightbox_notify_image_change(e){
  //CALLBACK when image has been changed

  //console.log("coco");
  //console.log("image "+e.index+" is now shown");
  embed_video_player(e.index); // if it's a video a video player will be embedeed
  $("#lightbox_controls .picture_title").empty();
  if (dive_pictures_data[e.index].data.title == null || dive_pictures_data[e.index].data.title == "")
    var title = I18n.t(["js","lightbox","Picture"]);
  else
    var title = dive_pictures_data[e.index].data.title;
  $("#lightbox_controls .picture_title").html(title+I18n.t(["js","lightbox"," by "])+ dive_pictures_data[e.index].user.nickname)
  set_active_image(e.index);
  update_fish_data(e.index);
  update_comment_count(e.index);
  fill_infos(dive_pictures_data[e.index]);
  lightbox_data["like_rendered"] = false;
  lightbox_data["comments_rendered"] = false;
  if(!$("#lightbox_controls .left_box_fish").is(":visible") && !$("#lightbox_controls .left_box_picture").is(":visible"))
    close_info_panels(); // we keep fish list open
  show_like_info();
}


function hide_lightbox(ev){
  if(ev)
    ev.preventDefault();
  // Reset the disqus comments box from the main page
  if ($("#lightbox_controls .disqus_thread iframe").length > 0){
    $("#view_dive .disqus_thread").attr('id', 'disqus_thread')
    $("#lightbox_controls .disqus_thread").attr('id', 'old_disqus_thread')
    DISQUS.reset({reload:true, config: disqus_config}) 
  }
          
  $("#lightbox").hide();
  $("#lightbox_controls").hide();
  diveboard.unlock_scroll();
  nuke_lightbox(); // otherwise the video doesn't stop
}


function lock_scroll_force(ev,x,y){
  if(ev)
    ev.preventDefault();
  window.scrollTo(x,y);
}

function init_lightbox_bindings(){
  if(G_lightbox_bindings_set)
    return;

  G_lightbox_bindings_set = true;

  $("#lightbox_close").live('click', hide_lightbox);
  $("#lightbox").mousemove(mouse_callback_disable_carousel);
  //$("#lightbox_zoom").click(toggle_zoom_mode);
  $("#lightbox_zoom").live('click',toggle_controls);
  $("#lightbox_bottom_controls .lightbox_pic_list li").live('click', open_image_from_picker);
  $("#lightbox_bottom_controls .lightbox_pic_list li img").live('mouseenter', show_bigger_thumb);
  $("#lightbox_bottom_controls .lightbox_pic_list li img").live('mouseleave', hide_bigger_thumb);
  $(window).resize(resize_lightbox);
  $("#lightbox_bottom_controls  #lightbox_picker_back").live('click',prev_lightbox_page);
  $("#lightbox_bottom_controls  #lightbox_picker_next").live('click',next_lightbox_page);
  $("#lightbox_bottom_controls .lightbox_pic_list ul").draggable(
    { axis: 'x',
      stop: function(event, ui){
        if (lightbox_data.list_offset()<0)
          $("#lightbox_bottom_controls .lightbox_pic_list ul").css("left", -lightbox_data.list_css_offset()+"px");
        if ( lightbox_data.list_offset()>lightbox_data.max_offset() )
          $("#lightbox_bottom_controls .lightbox_pic_list ul").css("left", -(lightbox_data.max_offset()-lightbox_data.list_css_offset())+"px");
      }
  });
  $("#lightbox_controls .fish_count").live('click', toggle_fish_info);
  $("#lightbox_controls  .info_box_content_click a").live('click', info_left_pane_clicked);

  $("#lightbox_controls .comments_count").live('click',toggle_comments_info);
  $("#lightbox_controls .info_button").live('click',toggle_picture_info);
  $("#lightbox_controls .like_button").live('click',toggle_like_info);
}
function toggle_zoom_mode(e){
  if(e)
    e.preventDefault();
  if($("#lightbox_zoom").hasClass("lightbox_zoom_fs")){
    //we are fulscreen we go "fit"
    set_zoom_fit();
  }else{
    set_zoom_zoom();
  }

}

function set_zoom_fit(){
  lightbox_photoswipe.settings.imageScaleMethod="fit"
  //lightbox_photoswipe.next(); lightbox_photoswipe.previous();
  lightbox_photoswipe.carousel.resetPosition();
  $("#lightbox_zoom").addClass("lightbox_zoom_fit").removeClass("lightbox_zoom_fs");
  show_controls();
  show_like_info();
}

function set_zoom_zoom(){
  lightbox_photoswipe.settings.imageScaleMethod="zoom"
  //lightbox_photoswipe.next(); lightbox_photoswipe.previous();
  $("#lightbox_zoom").addClass("lightbox_zoom_fs").removeClass("lightbox_zoom_fit");
  hide_controls();
  hide_like_info();
  close_info_panels();
  resize_lightbox();
}

function toggle_controls(e){
  if(e)
    e.preventDefault();
  if($("#lightbox_bottom_controls").is(":visible"))
    {
      hide_controls();
      hide_like_info();
      close_info_panels();
      $("#lightbox_zoom").addClass("lightbox_zoom_fs").removeClass("lightbox_zoom_fit");
      resize_lightbox();
    }
  else
    {
      show_controls();
      show_like_info();
      $("#lightbox_zoom").addClass("lightbox_zoom_fit").removeClass("lightbox_zoom_fs");
      resize_lightbox ();
    }
}

function resize_lightbox(e){
  $("#lightbox").css("height", $(window).height()-Number($("#lightbox").css("margin-top").match(/[0-9]+/)[0])-Number($("#lightbox").css("margin-bottom").match(/[0-9]+/)[0]));
  resize_lightbox_picker();
  try{
    center_video_player();
  }catch(e){}
  try{
    if(lightbox_photoswipe.documentOverlay)
      lightbox_photoswipe.documentOverlay.resetPosition();
    if (lightbox_photoswipe.carousel)
      lightbox_photoswipe.carousel.resetPosition();
    }catch(e){}
}
function show_controls(){
  $("#lightbox_bottom_controls").show();
  $("#lightbox").css("margin-bottom",$("#lightbox_bottom_controls").height()+'px' );
  resize_lightbox();
}
function hide_controls(){
  $("#lightbox_bottom_controls").hide();
  $("#lightbox").css("margin-bottom",'0px' );
  resize_lightbox();
}

function init_picture_picker(picture){
  //this will populate the lightbox controls
  $("#lightbox_bottom_controls .lightbox_pic_list ul").empty();
  $("#lightbox_bottom_controls .lightbox_pic_list ul").css("width",picture.length*45+"px");
  resize_lightbox_picker()
  lightbox_data.lightbox_picker_page = 0;
  $.each(picture, function(index,value){
    line = '<li><img src="'+picture[index].thumb+'" height="40" width="40" id="lightbox_picker_'+index+'" class="lightbox_thumbs" index="'+index+'"/><span class="symbol hidden">}</span></li>';
    $("#lightbox_bottom_controls .lightbox_pic_list ul").append(line);
  });

}
function resize_lightbox_picker(){
  if(lightbox_data.lightbox_has_scroller)
    lightbox_data.images_per_line = Math.floor(($(window).width()-lightbox_data.lightbox_scroll_controls_width)/45);
  else
    lightbox_data.images_per_line = Math.floor(($(window).width())/45);
  lightbox_data.total_number_pages = Math.floor($("#lightbox_bottom_controls .lightbox_pic_list li").length/lightbox_data.images_per_line);



  if($(window).width() < ($("#lightbox_bottom_controls .lightbox_pic_list li").length*45)){
    //we need scroller
    $("#lightbox_bottom_controls .lightbox_pic_list").css("width",($(window).width()-lightbox_data.lightbox_scroll_controls_width)+"px");
    $(".lightbox_picker_controls").show();
    lightbox_data.lightbox_has_scroller = true;
  }
  else{
    //no need for scroller
    $("#lightbox_bottom_controls .lightbox_pic_list").css("width",($(window).width())+"px");
    $(".lightbox_picker_controls").hide();
    lightbox_data.lightbox_has_scroller = false;
  }
}

function set_active_image(id){
  $("#lightbox_bottom_controls .lightbox_pic_list li").removeClass("selected");
  $($("#lightbox_bottom_controls .lightbox_pic_list li")[id]).addClass("selected");
  lightbox_make_selected_thumb_visible(id);
}

function open_image_from_picker(e){
  e.preventDefault();
  try{
    var id = Number($(e.currentTarget).find("img").attr("id").match(/[0-9]+/))
    lightbox_photoswipe.carousel.show(id);
  }catch(e){
    //console.log("Could not open picture");
    }
}

function prev_lightbox_page(e){
  e.preventDefault();
  change_lightbox_page("left");
}
function next_lightbox_page(e){
  e.preventDefault();
  change_lightbox_page("right");
}

function change_lightbox_page(direction){

  var page=0;
  for(i=0; i<=lightbox_data.total_number_pages;i++ ){
    if(lightbox_data.list_offset()>=(i)*45*lightbox_data.images_per_line  && lightbox_data.list_offset()<(i+1)*45*lightbox_data.images_per_line  ){
      //console.log("we're somewhere page :" + i);
      page = i;
    }
  }
  if(direction == "right"){
    move_lightbox_picker_topage(page+1);
  }  else if(direction == "left"){
    if(lightbox_data.list_offset()==(page)*45*lightbox_data.images_per_line)
      move_lightbox_picker_topage(page-1);
    else
      move_lightbox_picker_topage(page);
  }else{

  }



}

function lightbox_make_selected_thumb_visible(id){
  if(lightbox_data.lightbox_has_scroller){
    /*try{
      var list_offset = Number($(".lightbox_pic_list ul").attr("data-transform").match(/\-*[0-9]+/));
    }catch(e){
      var list_offset = 0;
    }*/
    var list_offset = lightbox_data.list_offset();

    if (!( ($("#lightbox_bottom_controls .lightbox_pic_list .selected").position().left-list_offset)<($(window).width()-lightbox_data.lightbox_scroll_controls_width-45) && ($("#lightbox_bottom_controls .lightbox_pic_list .selected").position().left-list_offset) > 0  )){
      //we need to scroll
      var new_page = Math.floor(id/ lightbox_data.images_per_line);
      //console.log("id "+id+" new page: "+new_page+ " images per line "+lightbox_data.images_per_line);
      move_lightbox_picker_topage(new_page);
    }

  }
}
function move_lightbox_picker_topage(pagenum){
  if (pagenum < 0)
    pagenum = lightbox_data.total_number_pages;

  if(pagenum > lightbox_data.total_number_pages)
    pagenum = 0;

  lightbox_data.lightbox_picker_page = pagenum;

  var offset = -pagenum*45*lightbox_data.images_per_line;
  //console.log("heading to offset "+offset);
  $("#lightbox_bottom_controls .lightbox_pic_list ul").css("left","0px");
  $(".lightbox_pic_list ul").animate({translateX: offset+'px'})
}


function toggle_fish_info(e){
  if(e)
    e.preventDefault();

  if($("#lightbox_controls .fish_count").hasClass("selected")){
    //we need to unselect
    close_info_panels()
  }else{
    //we need to select
    show_fish_info();
  }

}

function show_fish_info(){
  close_info_panels();
  $("#lightbox_controls .fish_count").addClass("selected");
  $("#lightbox_controls #yellow_pointer").addClass("fish");
  $("#lightbox_controls #yellow_pointer").show();
  $("#lightbox_controls .left_box_fish").show();
  $("#lightbox_controls .right_box").hide();
  try{$("#lightbox_controls #info_box .left_box_fish .info_box_content div a").first().click();}catch(e){}
}


function update_fish_data(idx){
  $("#lightbox_controls .right_box").hide();
  $("#lightbox_controls .fish_count span").html(dive_pictures_data[idx].data.species.length);
  if(dive_pictures_data[idx].data.species.length == 0){
    var fish_list="<ul><li>"+I18n.t(["js","lightbox","No fish have been identified on this picture yet"])+"</li></ul>"
  }else{
    var fish_list="<ul>";
    $.each(dive_pictures_data[idx].data.species, function(index,value){
      fish_list+="<li><a href='#' picture='"+idx+"' species='"+index+"'>";
      if(value.cname != "" && value.cname != null)
        fish_list += value.cname;
      else
        fish_list += value.sname;
      fish_list += "</a></li>";
    });
    fish_list += "</ul>";
  }
  $("#lightbox_controls #info_box .left_box_fish .info_box_content div").html(fish_list);
}

function info_left_pane_clicked(e){
  if(e)
    e.preventDefault();
  //ev = e;
  $("#lightbox_controls #info_box .right_box").css("height",""); // reset initial heights
  $("#info_box .info_box_content").css("height", '');// reset initial heights

  $("#lightbox_controls #info_box .left_box_fish a").removeClass("selected");
  $(e.currentTarget).addClass("selected");
  var pict_id = Number($(e.currentTarget).attr("picture"));
  var species_id = Number($(e.currentTarget).attr("species"));

  var species = dive_pictures_data[pict_id].data.species[species_id];
  var content="<h2>";
  if (species.cname != "" && species.cname != null)
    content += species.cname +" ("+species.sname+")</h2>";
  else
    content += species.sname+"</h2>"

  if(species.description != "" && species.description != null )
    content += "<p>"+species.description+"</p><p class='source_species'>"+I18n.t(["js","lightbox","Source:"])+" <a href='"+species.url+"'>EOL.org</a></p>";
  else
    content += "<p>"+I18n.t(["js","lightbox","No available description for this species. Feel free to submit one on"])+" <a href='"+species.url+"'>EOL.org</a></p>"

  $("#lightbox_controls .right_box span").html(content);
  $("#lightbox_controls #info_box .right_box").show();

  //$("#info_box .info_box_content").animate({height: ($("#lightbox_controls #info_box .right_box").outerHeight()-29)+"px"}, 200);
  if($("#lightbox_controls #info_box .right_box").outerHeight() > $("#info_box .left_box_fish").height())
    $("#info_box .info_box_content").css("height", ($("#lightbox_controls #info_box .right_box").outerHeight()-29)+"px");
  else
    $("#lightbox_controls #info_box .right_box").css("height", $("#info_box .left_box_fish").height()-20+"px")
  $("#lightbox_controls #info_box .right_box").css("background-position-y", ($("#lightbox_controls #info_box .right_box").outerHeight()/2-15)+"px");
}

function close_info_right_pane(e){
  if(e)
    e.preventDefault();
  //$("#info_box .info_box_content").animate({height: ''},200);
  $("#info_box .info_box_content").css("height", '');
  $("#lightbox_controls #info_box .right_box").css("height",""); // reset initial heights
  $("#lightbox_controls #info_box .right_box").hide();
  $("#lightbox_controls #info_box .left_box_fish a").removeClass("selected");
}


function toggle_comments_info(e){
  if(e)
    e.preventDefault();

  if($("#lightbox_controls .comments_count").hasClass("selected")){
    //we need to unselect
    close_info_panels();
  }else{
    //we need to select
    show_comments_info();
  }

}
function show_comments_info(){
  close_info_panels();
  $("#lightbox_controls .comments_count").addClass("selected");
  $("#lightbox_controls #yellow_pointer").addClass("comments");
  $("#lightbox_controls #yellow_pointer").show();
  $("#lightbox_controls .left_box_comments").show();
  if(!lightbox_data["comments_rendered"])
    update_comment_box();
}

function update_comment_box(){
  // var idx = lightbox_photoswipe.currentIndex;
  // var fbtag = '<div class="fb-comments" data-href="'+dive_pictures_data[idx].fullpermalink+'" data-num-posts="5" data-width="345" data-colorscheme="light" data-notify="true" data-send="false"></div>'
  // $("#lightbox_controls .lightbox_comments").empty();
  // $("#lightbox_controls .lightbox_comments").html(fbtag);
  // FB.XFBML.parse(document.getElementById('info_box')); //reparse the fbml
  // lightbox_data["comments_rendered"] = true;
  
  if ($("#lightbox_controls .disqus_thread iframe").length == 0){
    $("#view_dive .disqus_thread").attr('id', 'old_disqus_thread')
    $("#lightbox_controls .disqus_thread").attr('id', 'disqus_thread')
    DISQUS.reset({reload:true, config: disqus_config})
  }
        

}
function update_comment_count(idx){
  var dsqtag = '<span class="disqus_comment_count"></span>'
  $("#lightbox_controls .comments_count span").empty().html(dsqtag);

  // FB.XFBML.parse(document.getElementById('lightbox_bottom_controls')); //reparse the fbml
  update_all_disqus_count();
}

function update_all_disqus_count(){
  var comments_count = 0;
  // $(".disqus_comment_count").html('0');
  //ajax disqus_identifier
  console.log("ABOUT TO MAKE DISQUS API CALL FOR THE COMMENT COUNT")
  $.ajax({
    type: 'GET',
    url: "https://disqus.com/api/3.0/threads/details.jsonp",
    data: { api_key: disqus_public_key, forum : disqus_shortname, 'thread:ident' : disqus_identifier },
    cache: false,
    dataType: 'jsonp',
    success: function (result) {
      $(".disqus_comment_count").empty().html(result.response.posts);
    }
  });

  
}

function show_bigger_thumb(e){
  eva = e;
  if(e)
    e.preventDefault();
  $("#lightbox_controls .ligbtbox_pic_zoomed").css("background-image", "url("+dive_pictures_data[Number($(e.target).attr("index"))].thumb+")");
  $("#lightbox_controls .ligbtbox_pic_zoomed").css("display","inline-block");

  var off = $(e.target).parent().position().left - lightbox_data["list_offset"]() - 30;
  console.log("moving to offset "+off);
  if (off < 0)
    off = 0;
  if ((off+100) > $(window).width())
    off = $(window).width() - 100;
  $("#lightbox_controls .ligbtbox_pic_zoomed").css("left",off+"px");

}
function hide_bigger_thumb(e){
  evo = e;
  $("#lightbox_controls .ligbtbox_pic_zoomed").css("display","none");
  $("#lightbox_controls .ligbtbox_pic_zoomed").css("background-image: none");

}

function close_info_panels(){
  //console.log("closing panels");
  $("#lightbox_controls .top_lightbox_controls div").removeClass("selected");
  $("#lightbox_controls #yellow_pointer").removeClass("comments");
  $("#lightbox_controls #yellow_pointer").removeClass("fish");
  $("#lightbox_controls #yellow_pointer").removeClass("picture");
  $("#lightbox_controls #yellow_pointer").removeClass("like");
  $("#lightbox_controls #yellow_pointer").hide();
  $("#lightbox_controls .left_box_comments").hide();
  $("#lightbox_controls .left_box_fish").hide();
  $("#lightbox_controls .left_box_picture").hide();
  $("#lightbox_controls .left_box_like").hide();
  close_info_right_pane();
}

function toggle_picture_info(e){

  if(e)
     e.preventDefault();

   if($("#lightbox_controls .info_button").hasClass("selected")){
     //we need to unselect
     close_info_panels();
   }else{
     //we need to select
     show_picture_info();
   }
}
function show_picture_info(){
  close_info_panels();
  $("#lightbox_controls .info_button").addClass("selected");
  $("#lightbox_controls #yellow_pointer").addClass("picture");
  $("#lightbox_controls #yellow_pointer").show();
  $("#lightbox_controls .left_box_picture").show();
  fill_infos(dive_pictures_data[lightbox_photoswipe.currentIndex]);

}
function fill_infos(image){
  var exif_data ="";
  if(image.exif.Model && image.exif.Make)
    exif_data += "<p><strong>"+I18n.t(["js","lightbox","Camera"])+"</strong>: "+image.exif.Make+" - "+image.exif.Model+"</p>";
  if(image.exif.Lens && image.exif.MaxApertureValue && image.exif.FNumber && image.exif.ExposureTime && image.exif.Flash)
    exif_data += "<p><strong>"+I18n.t(["js","lightbox","Lens"])+"</strong>: "+image.exif.Lens+", F"+image.exif.MaxApertureValue+" @ F"+image.exif.FNumber+" "+image.exif.ExposureTime+" "+image.exif.Flash+" "+image.exif.ISO+"ISO</p>";

  $("#lightbox_controls .info_box_exif").empty().html(exif_data);
  if(exif_data == "")
    $("#lightbox_controls .box_exif").hide();
  else
    $("#lightbox_controls .box_exif").show();

  var spot_data = "<p><img src='"+image.spot.staticmap+"'/>"+image.spot.country_name+", "+image.spot.location_name+", "+image.spot.name;
  spot_data += "<br/>"+image.dive.date;

  $("#lightbox_controls .info_box_spot").empty().html(spot_data);

}



function toggle_like_info(e){
  if(e)
     e.preventDefault();

   if($("#lightbox_controls .like_button").hasClass("selected")){
     //we need to unselect
     close_info_panels();
   }else{
     //we need to select
     close_info_panels();
     $("#lightbox_controls #yellow_pointer").addClass("like");
     $("#lightbox_controls #yellow_pointer").show();
     $("#lightbox_controls .left_box_like").show();
     $("#lightbox_controls .like_button").addClass("selected");
   }
}

function hide_like_info(){
  $("#lightbox_top_left_controls").hide();
}


function show_like_info(){
  $("#lightbox_top_left_controls").show();
  if(!lightbox_data["like_rendered"])
  {
    var idx = lightbox_photoswipe.currentIndex;
    var permalink = dive_pictures_data[idx].fullpermalink;
    var tinylink = dive_pictures_data[idx].tinylink;
    var image_link = dive_pictures_data[idx].image_large;
    if (dive_pictures_data[idx].data.title == null)
      var caption =  "Scuba picture by "+dive_pictures_data[idx].user.nickname;
    else
      var caption =  dive_pictures_data[idx].data.title + " by "+dive_pictures_data[idx].user.nickname;
    var fblike = '<div class="fb-like" data-href="'+permalink+'" data-send="false" data-layout="button_count" data-width="450" data-show-faces="false"></div>';
    var plusone = '<g:plusone callback="notify_google_like" href="'+permalink+'" data-send="false"></div></g:plusone>';
    var pinterest = '<a href="//pinterest.com/pin/create/button/?url='+encodeURIComponent(permalink)+'&media='+encodeURIComponent(image_link)+'&description='+encodeURIComponent(caption)+'" class="pin-it-button" data-pin-do="buttonPin" data-pin-config="none"></a>';
    var twitter = '<a href="//twitter.com/share" class="twitter-share-button" data-url="'+tinylink+'" data-via="diveboard" data-related="diveboard" data-hashtags="scuba" data-text="'+caption+'" data-count="none">Tweet</a><script>!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0];if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.async=true;js.src="//platform.twitter.com/widgets.js";fjs.parentNode.insertBefore(js,fjs);}}(document,"script","twitter-wjs");</script>'
    //var addthis_b = '<div class="addthis_toolbox addthis_default_style" addthis:url="'+permalink+'" addthis:title="'+caption+'"><a class="addthis_button_preferred_1"></a><a class="addthis_button_preferred_2"></a><a class="addthis_button_preferred_3"></a><a class="addthis_button_preferred_4"></a><a class="addthis_button_compact"></a><a class="addthis_counter addthis_bubble_style"></a></div>';
    //$("#lightbox_controls .fb_like_button").empty().html(addthis_b);
    //addthis.init();
    $("#lightbox_controls .fb_like_button").empty().html(fblike);
    $("#lightbox_controls .plusone_like_button").empty().html(plusone);
    $("#lightbox_controls .twitter_like_button").empty().html(twitter);
    $.ajax({ url: 'http://platform.twitter.com/widgets.js', dataType: 'script', cache:true}); //http://www.ovaistariq.net/447/how-to-dynamically-create-twitters-tweet-button-and-facebooks-like-button/
    $("#lightbox_controls .pinterest_like_button").empty().html(pinterest);
    $("#lightbox_controls .permalink_field input").val(tinylink);
    diveboard.plusone_go();//render +1 button
    FB.XFBML.parse(document.getElementById('lightbox_controls')); //reparse the fbml
    lightbox_data["like_rendered"] = true;
    if (typeof pin_build_api != 'undefined') pin_build_api($("#lightbox_controls .pinterest_like_button")[0])
  }
}

function center_video_player(){
  var holder = lightbox_data["video_holder"];
  if($(holder).find(".video_player").length == 1)
  {
    var iframe = $(holder).find(".video_player").children();
    var height = iframe.height();
    var width = iframe.width();
    $("#lightbox .video_player").css("height", height+"px").css("width", width+"px");
    var top = ($("#lightbox .ps-carousel").height() - height)/2;
    //var left = ($("#lightbox .ps-carousel").width() - width)/2;
    var frame = $("#lightbox .video_player");

    if (top < 0 )
      top = 0;
    $("#lightbox .video_player").css("margin-top", top+"px");

    lightbox_data["video_coords"]=[frame.offset().left, frame.offset().top, frame.offset().left+frame.width(), frame.offset().top+frame.height()];
  }else{
    lightbox_data["video_coords"]=[0,0,0,0];
  }
}

function embed_video_player(idx){
  if(dive_pictures_data[idx].player == null){
    //This is actaully a picture
      lightbox_data["video_rendered"] = false;
      lightbox_data["video_holder"] = "";
      lightbox_data["video_coords"]=[0,0,0,0];
      lightbox_photoswipe.settings.allowUserZoom = true;
      return;
    }
  lightbox_photoswipe.settings.allowUserZoom = false;

  //we need to find where the picture is being held hostage of the photoswipe
  for(var i=0; i< $("#lightbox .ps-carousel-item").length; i++){
    if ($($("#lightbox .ps-carousel-item")[i]).find("img").attr("src") == dive_pictures_data[idx].image_large)
       lightbox_data["video_holder"] = $("#lightbox .ps-carousel-item")[i];
  }


    var holder = lightbox_data["video_holder"];

  if ($(holder).find(".video_player").length != 1)
    {
      if ($("#lightbox .ps-document-overlay").height() >= 560 && $("#lightbox .ps-document-overlay").width() >= 1000)
        $(holder).html("<div class='video_player'>"+dive_pictures_data[idx].player_big+"</div>");
      else if ($("#lightbox .ps-document-overlay").height() >= 360 && $("#lightbox .ps-document-overlay").width() >= 640)
        $(holder).html("<div class='video_player'>"+dive_pictures_data[idx].player+"</div>");
      else
        $(holder).html("<div class='video_player'>"+dive_pictures_data[idx].player_small+"</div>");

       //$(holder).html("<object width=\"853\" height=\"480\" id=\"flash_video_lightbox\"><param name=\"movie\" value=\"http://www.youtube.com/v/rn1vJO37yIo?version=3&amp;hl=en_US\"></param><param name=\"allowFullScreen\" value=\"true\"></param><param name=\"allowscriptaccess\" value=\"always\"></param><embed src=\"http://www.youtube.com/v/rn1vJO37yIo?version=3&amp;hl=en_US\" type=\"application/x-shockwave-flash\" width=\"853\" height=\"480\" allowscriptaccess=\"always\" allowfullscreen=\"true\"></embed></object>");

       //$(holder).html("<div id='flash_video_lightbox' class='video_player'></div>");
       //swfobject.embedSWF("http://www.youtube.com/v/rn1vJO37yIo?enablejsapi=1&amp;version=3&amp;border=0", "flash_video_lightbox", "576", "356", "8", null, null);
       //$("#flash_video_lightbox").hide().show();

       //swfobject.registerObject("flash_video_lightbox", "9", "/img/expressInstall.swf");
      mp = $('video,audio').mediaelementplayer({
        features: ['playpause','progress','current','duration','volume'],
        pluginPath: "/img/mediaelement/"
      });
    }
  lightbox_data["video_rendered"] = true;
  center_video_player();
}

function mouse_callback_disable_carousel(e){
  //if (e)
  //  e.preventDefault();
  if($("#lightbox").is(":visible") && $("#lightbox .ps-uilayer").is(":visible") && is_mouse_on_video(e))
    {
      //console.log("deactivating events");
      //console.log([e.pageX, e.pageY].toString()+" vs "+lightbox_data["video_coords"].toString());
      $("#lightbox .ps-zoom-pan-rotate").hide();
      $("#lightbox .ps-uilayer").hide();
    }
  if($("#lightbox").is(":visible") && !$("#lightbox .ps-uilayer").is(":visible") && !is_mouse_on_video(e))
    {
      //console.log("activating events");
      //console.log([e.pageX, e.pageY].toString()+" vs "+lightbox_data["video_coords"].toString());
      $("#lightbox .ps-zoom-pan-rotate").show();
      $("#lightbox .ps-uilayer").show();
    }
}
function is_mouse_on_video(e){
  var margin = 10;
  return (lightbox_data["video_rendered"] && e.pageX>lightbox_data["video_coords"][0]-margin && e.pageX < lightbox_data["video_coords"][2]+margin && e.pageY>lightbox_data["video_coords"][1]-margin && e.pageY < lightbox_data["video_coords"][3]+margin)
}
