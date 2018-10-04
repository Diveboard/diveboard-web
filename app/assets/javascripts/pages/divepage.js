var auth_token = $("meta[name='csrf-token']").attr("content");
var wizard_first_init = true;
var G_wizard_values = [];
var G_wizard_tabs = [];


//JAVASCRIPT UNIT CONVERSION HELPERS
function unit_temp(temperature, addunit){
  if (G_unit_temperature == "C") {
    if (addunit)
      return temperature+"ºC"
    else
      return temperature
  }
  else {
    if (addunit)
      return Math.round(temperature*9/5+32)+"ºF"
    else
      return Math.round(temperature*9/5+32)
  }
}
function unit_distance(distance, addunit){
  if (G_unit_distance == "m") {
    if (addunit)
      return distance+"m"
    else
      return distance
  } else {
    if (addunit)
      return Math.round(distance*3.2808399*10)/10+"ft"
    else
      return Math.round(distance*3.2808399*10)/10
  }
}

function unit_distance_label(){
  if (G_unit_distance == "m") {
    return "m"
  } else {
    return "ft"
  }
}



function dive_ready(){
  //Called AFTER all is loaded

  //Change featured image size and position for landscape pictures
  $("#featured_pic").imagesLoaded(function(){
    if ($("#featured_pic").length) {
      if ($("#featured_pic")[0].naturalHeight > $("#featured_pic")[0].naturalWidth) {
        var pseudoHeight = $("#featured_pic")[0].naturalHeight * $("#featured_pic").width() / $("#featured_pic")[0].naturalWidth;
        $("#featured_pic").css("top", ""+(-(pseudoHeight-$("#featured_pic").height())/2)+"px");
        $("#featured_pic").height(pseudoHeight);
        $("#featured_pic").show();
      }
      else
      {
        var pseudoWidth = $("#featured_pic")[0].naturalwidth * $("#featured_pic").height() / $("#featured_pic")[0].naturalHeight;
        $("#featured_pic").css("top", ""+(-(pseudoWidth-$("#featured_pic").width())/2)+"px");
        $("#featured_pic").width(pseudoWidth);
        $("#featured_pic").show();
      }
    }
  });
  diveboard.plusone_go();

  //scroll on dive's note
  try {
    $(".divers_comments_text").jScrollPane({showArrows: false, hideFocus:true})
  } catch(e) {}

  //unload all tooltips

  //load tooltips
  $('.tooltiped-js').qtip({
    style: {
      tip: { corner: true },
      classes: "ui-tooltip-diveboard"
    },
    position: {
      at: "bottom center",
      my: "top right"
    },
    hide: {
             fixed: true,
             delay: 300
         }
  });

  $('.tooltiped-js-middle').qtip({
    style: {
      tip: { corner: true },
      classes: "ui-tooltip-diveboard"
    },
    position: {
      at: "bottom center",
      my: "top center"
    },
    hide: {
             fixed: true,
             delay: 300
         }
  });


  share_initialize();

  //gmaps_initialize("map_canvas", false);

  //initialise the dive editor
  //select all the a tag with name equal to modal
  $('a[name=modal]').click(show_wizard);
  wizard_first_init = true;

  //initialize the jquery bindings
    id_list = new Array();
    for (var i = 0; i < dive_pictures_data.length ; i++) {
      id_list.push(dive_pictures_data[i].id);
    };
    LightFrame.init(id_list);
  $("#tab_pictures_link").click(show_pictures_tab);
  $("#tab_map_link").click(show_map_tab);
  $("#tab_ppl_link").click(show_ppl_tab);
  $("#tab_species_link").click(show_species_tab);
  $("#tab_dan_link").click(show_dan_tab);
  $("#overview_featured_pict").click(show_featured_picture);
  $("#tab_overview_link").click(show_overview_tab);
  $("#tab_profile_link").click(show_profile_tab);
  $("#tab_gear_link").click(show_gear_tab);
  $("#tab_share_link").click(show_share_tab);
  $("#privacy").click(change_privacy);
  $("#graph_small").click(show_profile_tab);

//update the url
  $(".tab_link").live('click', function(e) {
    var tab_name = $(this).attr('id').replace(/_link$/,'');
    if(window.history.pushState){
      var uri_parser = document.createElement("a");
      uri_parser.href = G_page_fullpermalink;
      window.history.pushState("","",uri_parser.pathname+"#"+tab_name.replace("tab_",""));
    }
  });


  //initialize yoxvox for video support
  //$("#video").die('click');
  //$("#video").ceebox({"imageWidth": 400, imageHeight: 600, callback_popup: ceebox_addtags});

  initialize_follow_links();
  $(document).ready(function()
    {
      $("input.star").rating();
    });
  //alert("load");
  //$("head").append($("<link rel='stylesheet' href='https://dev.diveboard.com/js/jquery.rating.3.14.js' type='text/css' media='screen' />"));
  //initialize_css();
  // reset_default();
}

function ceebox_addtags(ceeobj, content_id)
{
  var height = ceeobj.height();
  var other_content = $("#comment_"+content_id).clone(false);
  other_content.find('.tooltiped-js').qtip({
    style: {
      tip: { corner: true },
      classes: "ui-tooltip-diveboard"
    },
    position: {
      at: "bottom center",
      my: "top right"
    },
    hide: {
             fixed: true,
             delay: 300
         }
  });

  ceeobj.append(other_content);
  ceeobj.height(height + other_content.height());
}

/*
*
* wizard INITIALIZE
*
*
*/


function share_initialize(){
  //Get the screen height and width
  var maskHeight = $(document).height();
  var maskWidth = $(window).width();

  //Set heigth and width to mask to fill up the whole screen
  $('#share_mask').css({'width':maskWidth,'height':maskHeight});

  $('#diveboard_share_menu').hide();
  $('#share_mask').hide();
  $("#share_this_link").click(function (e) {
    if (e != null){
      e.preventDefault();
    }
    $('#diveboard_share_menu').fadeIn('fast');
    $('#share_mask').fadeIn('fast');
  });
  $("#share_mask").click(function (e) {
    if (e != null){
      e.preventDefault();
    }
    $('#diveboard_share_menu').hide();
    $('#share_mask').hide();
  });

  $("#share_close").click(function (e) {
    if (e != null){
      e.preventDefault();
    }
    $('#diveboard_share_menu').hide();
    $('#share_mask').hide();
  });
}


/*
*
* JUNK FUNCTIONS FOR MECHANICS (HIDE/SHOW)
*
*/

function show_tab(tab_name)
{
	$("#fbcomments").show();
  $(".tab_link").removeClass('active');
  $("#tab_"+tab_name+"_link").addClass('active');
  $(".tab_panel").hide();
  $(".tab_"+tab_name).css('display', 'inline');
	if (tab_name != "share")
		$("#updated_dive_confirmation").hide();
}

function show_ppl_tab(ev){
  if (ev) ev.preventDefault();

  try {
    if ($("#set_spot_details").is(":visible") && !wizard_check_create_spot(show_ppl_tab, false))
      return(false);
  } catch(e){}

  show_tab("ppl");
}

function show_dan_tab(ev){
  if (ev) ev.preventDefault();
  try {
    if ($("#set_spot_details").is(":visible") && !wizard_check_create_spot(show_dan_tab, false))
      return(false);
  } catch(e){}


check_dan_form_status(G_current_private_dive['dan_data'], G_current_private_dive['dan_data_sent'], false);
  show_tab("dan");
}

function show_gear_tab(ev){
  if (ev) ev.preventDefault();

  try {
    if ($("#set_spot_details").is(":visible") && !wizard_check_create_spot(show_gear_tab, false))
      return(false);
  } catch(e){}

  show_tab("gear");
}
function show_species_tab(ev){
  if (ev) ev.preventDefault();

  show_tab("species");
}

function show_map_tab(ev)
{
  if (ev) ev.preventDefault();
  show_tab("map");

  wizard_gmaps_init($("#wizardgmaps").data("db-editable"));

  if($("#tab_gmap_holder").is(":visible")){
    if(!gmaps_initialized){
      gmaps_initialize("tab_gmap_holder", false);

      gmaps_initialized = true;
    }else{
      try {
        map.setCenter(marker.position);
      } catch(e){}
    }
  }
}

function show_featured_picture(ev){
  //G_show_picture = G_dive_featured_picture;
  //show_pictures_tab(ev);
  //open_lightbox(0);
  LightFrame.displayLive(dive_pictures_data[0].id);
}

function show_pictures_tab(ev)
{
  if (ev) ev.preventDefault();

  try {
    if ($("#set_spot_details").is(":visible") && !wizard_check_create_spot(show_pictures_tab, false))
      return(false);
  } catch(e){}

  show_tab("pictures");

  try {
    wizard_initialize_galleria()
  } catch(e){
    track_exception_global(e)
  }


  // Load the classic theme
  // Initialize Galleria
  if (!galleria_initialized){
    $("#galleria").neat_gallery({
      source: dive_pictures_data,
      max_height: 100,
      width: 600,
      coverIndex: G_dive_picture_cover,
      onclick: function(idx, img, evt){ 
        LightFrame.displayLive(img['requested']['data']['id']);
        },
      loaded: function(){ $("#galleria-loading").hide();  }
    });
    if(G_show_picture && G_show_picture != "") {

      //We need to find the picture and open it.
      for(var i=0; i<dive_pictures_data.length; i++){
        if(dive_pictures_data[i].id == Number(G_show_picture))
        {
          open_lightbox(i);
          break;
        }
      }
      G_show_picture ="";
    }

    galleria_initialized = true;
  }
  $(".picture_permalink input").live("click", function(){
    $(this).parent().find(".notice").show();
    this.select();
    $(this).parent().find(".notice").fadeOut(5000);
  });
}

function show_overview_tab(ev){
  try {
    if (ev)
      ev.preventDefault();
  } catch(e){}

  try {
    if ($("#set_spot_details").is(":visible") && !wizard_check_create_spot(show_overview_tab, false))
      return(false);
  } catch(e){}

  show_tab("overview");

}

function show_profile_tab(ev){
  if (ev) ev.preventDefault();
  try {
    if ($("#set_spot_details").is(":visible") && !wizard_check_create_spot(show_profile_tab, false))
      return(false);
  } catch(e){}
  show_tab("profile");
}

function show_share_tab(ev){
  if (ev) ev.preventDefault();
    show_tab("share");
}


function change_privacy(e){
  //1 is private
  //0 is public
  if (e) e.preventDefault();

  //$("#privacy img").qtip("destroy"); //remove the tooltip before it sticks

  diveboard.mask_file(true, {'z-index': 90000});
  $("#privacy").empty();
  //$("#privacy").prepend('<img src="/img/loading.gif" />');
  if (privacy == 0) { privacy = 1;}
  else if (privacy == 1) { privacy = 0;}
  var url = "/api/setprivacy/"+G_dive_id+".json";

  $.ajax({
    url: url,
    dataType: 'json',
    data: ({
      dive_id: G_dive_id,
      'authenticity_token': auth_token,
      privacy: privacy
      }),
    type: "POST",
    success: function(data){
      if (data.success) {
        $(".qtip").hide();
        dive_updated = true;
        showDive(G_dive_id,true);
        $("#wizard_export_list [name='"+G_dive_id+"']").attr("privacy", data.privacy);
        if(privacy == 0)
          $("#dive"+G_dive_id+" .dive_bullet_column div").addClass("dive_bullet").removeClass("dive_bullet_private");
        else
          $("#dive"+G_dive_id+" .dive_bullet_column div").removeClass("dive_bullet").addClass("dive_bullet_private");

      } else
        diveboard.alert(I18n.t(["js","divepage","A technical error occured while changing the privacy. Please try again after having reloaded the page."]), data);
    },
    error: function(data){
      diveboard.alert(I18n.t(["js","divepage","A technical error occured while changing the privacy. Please try again after having reloaded the page."]));
    }
  });
}

/*
*
* GMAPS
*
*/

var map;
var marker=null;
var geocoder;

function gmaps_initialize(domID, draggable) {

  var lat = parseFloat($("#spot-lat").val());
  var lng = parseFloat($("#spot-long").val());
  var zoom = parseInt($("#spot-zoom").val());

  if(isNaN(lat) || isNaN(lng) || isNaN(zoom)) {
    var lat = G_spot_lat;
    var lng = G_spot_long;
    var zoom = G_spot_zoom;
  }

  try {
    var image = new google.maps.MarkerImage('/img/marker.png',
      // This marker is 20 pixels wide by 32 pixels tall.
      new google.maps.Size(19, 23),
      // The origin for this image is 0,0.
      new google.maps.Point(0,0),
      // The anchor for this image is the base of the flagpole at 0,23.
      new google.maps.Point(9, 23)
    );
    var shadow = new google.maps.MarkerImage('/img/mark_shadow.png',
      // The shadow image is larger in the horizontal dimension
      // while the position and offset are the same as for the main image.
      new google.maps.Size(19, 23),
      new google.maps.Point(0,0),
      new google.maps.Point(0, 23)
    );
      // Shapes define the clickable region of the icon.
      // The type defines an HTML <area> element 'poly' which
      // traces out a polygon as a series of X,Y points. The final
      // coordinate closes the poly by connecting to the first
      // coordinate.


    var latlng = new google.maps.LatLng(lat,lng);
    var myOptions = {
      zoom: zoom,
      minZoom: 1,
      center: latlng,
      mapTypeId: google.maps.MapTypeId.HYBRID,
      panControl: false,
      zoomControl: true,
      mapTypeControl: false,
      scaleControl: false,
      streetViewControl: false
    };
    map = new google.maps.Map(document.getElementById(domID),myOptions);
    //var image = '/img/mappin.png';
    var myLatLng = new google.maps.LatLng(lat,lng);
    marker = new google.maps.Marker({
      position: myLatLng,
      map: map,
      icon: image,
      shadow: shadow,
      draggable: draggable
    });
  } catch(e){}
}






/*
*
* FUNCTIONS TO  CHECK AND UPDATE DATA
*
*
*/

var diveboardCopyDive = function(){};


diveboardCopyDive.init_copy_dive_to_logbook = function(){

  //bindings
  $("#dialog-copy-dive .copy_dive_ok").unbind('click');
  $("#dialog-copy-dive .copy_dive_ok").bind('click', function(){
    var includes = {};
    $("#dialog-copy-dive .filter_what_copy:checked").each(function(i,e){
      includes[$(e).attr('name')] = true;
    });
    $("#dialog-copy-dive").dialog('destroy');
    diveboardCopyDive.copy_dive_to_logbook(includes, function(data){
      $("#dialog-copied-dive .copied_dive_ok").attr('href', data.result.permalink);
      $("#dialog-copied-dive").dialog({width: 500, zIndex: 99999 });
    });
  });

  $("#dialog-copy-dive .copy_dive_cancel").unbind('click');
  $("#dialog-copy-dive .copy_dive_cancel").bind('click', function(){
    $("#dialog-copy-dive").dialog('destroy');
  });

  $("#dialog-copied-dive .copied_dive_cancel").unbind('click');
  $("#dialog-copied-dive .copied_dive_cancel").bind('click', function(){
    $("#dialog-copied-dive").dialog('destroy');
    diveboard.unmask_file();
  });

  $("#dialog-copied-dive .copied_dive_ok").unbind('click');
  $("#dialog-copied-dive .copied_dive_ok").bind('click', function(){
    $("#dialog-copied-dive").dialog('destroy');
    diveboard.unmask_file();
  });

  $("#dialog-copy-dive li").bind('click', function(e){
    var cb = $(this).find('.filter_what_copy');
    cb.prop("checked", !cb.prop("checked"));
  });

  $("#dialog-copy-dive li .filter_what_copy").bind('click', function(e){
    if(e && e.stopPropagation)
      e.stopPropagation();
    else {
      e = window.event;
      e.cancelBubble = true;
    }
  });


  //Form reset
  $("#dialog-copy-dive .filter_what_copy").attr('checked', 'checked');

  $("#dialog-copy-dive").dialog({width: 500, zIndex: 99999 });
  $(".ui-dialog").position({
   my: "center",
   at: "center",
   of:".ui-widget-overlay"
  });
}

diveboardCopyDive.copy_dive_to_logbook = function(includes, callback){
  includes = includes || {"basic": true, "conditions": true, "shop": true, "buddies": true, "profile": true, "spot": true, "add_buddy": true };


  diveboard.mask_file(true)

  diveboard.api_call('dive', {id:G_dive_api.id}, function(data){
      var data_to_send = {
        user_id: G_user_api.id,
        spot: {id: G_dive_api.spot_id},
        time_in: G_dive_api.time_in,
        duration: G_dive_api.duration,
        maxdepth: G_dive_api.maxdepth,
        safetystops: G_dive_api.safetystops,
        privacy: (G_user_api.auto_public?0:1)
      };

      if (G_user_api.id == G_owner_api.id)
        $.extend(data_to_send, {
          divetype: data.result.divetype
        });

      if (includes.conditions)
        $.extend(data_to_send, {
          visibility: G_dive_api.visibility,
          current: G_dive_api.current,
          temp_surface: G_dive_api.temp_surface,
          temp_bottom: G_dive_api.temp_bottom,
          water: G_dive_api.water,
          altitude: G_dive_api.altitude
        });

      if (includes.shop && G_dive_api.guide)
        $.extend(data_to_send, {
          guide: G_dive_api.guide
        });

      if (includes.shop && G_dive_api.shop_id)
        $.extend(data_to_send, {
          shop: {id: G_dive_api.shop_id}
        });


      if (includes.buddies && G_dive_api.buddies)
        $.extend(data_to_send, {
          buddies: G_dive_api.buddies
        });

      if (includes.profile && data.result.raw_profile)
        $.extend(data_to_send, {
          raw_profile: data.result.raw_profile
        });

      if (includes.species && data.result.species)
        $.extend(data_to_send, {
          species: data.result.species
        });

      if (includes.trip && data.result.trip_name)
        $.extend(data_to_send, {
          trip_name: data.result.trip_name
        });

      if (includes.weights && data.result.weights)
        $.extend(data_to_send, {
          weights: data.result.weights
        });

      if (includes.add_buddy)
        if (data_to_send.buddies)
          data_to_send.buddies.push({db_id: G_owner_api.id});
        else
          $.extend(data_to_send, { buddies:[{db_id: G_owner_api.id}] });


      diveboard.api_call('dive', data_to_send, function(data){
        if (callback) callback.apply(window, [data]);
        else diveboard.unmask_file();
        }, function(data){
          diveboard.unmask_file();
        }, 'public');
    }, function(data){
      diveboard.unmask_file();
    }, 'public,private,dive_profile');

}




/*
*
* DATA PROCESSING FUNCTIONS AND ASSET CREATION
*
*
*/
function parse(textDoc){
  try{
    if(typeof ActiveXObject!="undefined"&&typeof GetObject!="undefined"){
      var b=new ActiveXObject("Microsoft.XMLDOM");
      b.loadXML(textDoc);
      return b;
    }else if(typeof DOMParser!="undefined"){
      return(new DOMParser()).parseFromString(textDoc,"text/xml");
    }else{
      return Wb(textDoc);
    }
  } catch(c){
    P.incompatible("xmlparse");
  }
  try{
    return Wb(textDoc);
  } catch(c){
    P.incompatible("xmlparse");
    return document.createElement("div");
  }
}

function clone_to_doc(node,doc){
  if (!doc) doc=document;
  var clone = doc.createElementNS(node.namespaceURI,node.nodeName);
  for (var i=0,len=node.attributes.length;i<len;++i){
    var a = node.attributes[i];
    clone.setAttributeNS(a.namespaceURI,a.nodeName,a.nodeValue);
  }
  for (var i=0,len=node.childNodes.length;i<len;++i){
    var c = node.childNodes[i];
    clone.insertBefore(
      c.nodeType==1 ? clone_to_doc(c,doc) : doc.createTextNode(c.nodeValue),
      null
    );
  }
  return clone;
}

function load_tmpsvg_into(selector, fileid, index, type)
{
  var url_unit = ""
  if (G_unit_distance != "m") url_unit = "&u=i"
  else url_unit = "&u=m"

  var url_svg = "/api/profilefromtmp.svg?file="+fileid+"&index="+index+"&g="+type+url_unit;
  var url_png = "/api/profilefromtmp.png?file="+fileid+"&index="+index+"&g="+type+url_unit;

  $(selector).html("<div style='text-align: center; height: 125px; padding-top: 50px;'><img src='/img/transparent_loader.gif' /></div>");

  load_svg_into(selector, url_svg, url_png);
}

function load_divesvg_into(selector, type)
{
  var url_unit = ""
  if (G_unit_distance != 'm') url_unit = "&u=i"
  else url_unit = "&u=m"

  var url_svg = "/"+G_owner_vanity_url+"/"+G_dive_id+"/profile.svg?g="+type+url_unit;
  var url_png = "/"+G_owner_vanity_url+"/"+G_dive_id+"/profile.png?g="+type+url_unit;

  load_svg_into(selector, url_svg, url_png);
}

function load_svg_into(selector, url_ok, url_fail)
{
  try {
    var svg_support = true;
    try {
      svg_support = document.implementation.hasFeature("http://www.w3.org/TR/SVG11/feature#BasicStructure", "1.1")
    } catch(e){}

    if (svg_support) {
      $.ajax({
        url: url_ok,
        success: function(data){
          try {
            var c = clone_to_doc(data.getElementsByTagName("svg")[0], document);
            $(selector).html(c);
          } catch(e) {
            $(selector).html("<img src='"+url_fail+"' alt='profile' />");
          }
        },
        error: function() {
          $(selector).html("<img src='"+url_fail+"' alt='profile' />");
        }
      });
    }
    else {
      $(selector).html("<img src='"+url_fail+"' alt='profile' />");
    }
  } catch(e) {
    $(selector).html("<img src='"+url_fail+"' alt='profile' />");
  }
}

function showPopup(url) {
  newwindow = window.open(url,'name','height=190,width=520,top=200,left=300,resizable');
  if (window.focus) {newwindow.focus();}
}

function show_more_bio(e){
  $(e).parent().hide();
  $(e).parent().parent().find(".species_bio_full").show();
}
