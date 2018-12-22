var auth_token = $("meta[name='csrf-token']").attr("content");
var G_facebook_buddy_search_init = false;
var image_resizer;
var gmap_markers_simmilar = [];
var marker_simmilar_highlight = null;
var alternate_position_marker = null;
var alternate_position_markers = null;
var rever_geocode_debug = true;
var reverse_geocode_latest_result = null;
// if wizard_bulk == true => we're here to bulk create upload
// if false it's a one-dive creation

//UNIT HELPER FUNCTION
//TO MAKE SURE WE GET metric system data at the end of the day...

function highlight_term(value, term) {
  return value.replace(new RegExp("(?![^&;]+;)(?!<[^<>]*)(" + $.ui.autocomplete.escapeRegex(term) + ")(?![^<>]*>)(?![^&;]+;)", "gi"), "<b>$1</b>");
  //return value;

}

function sleep(millis)
{
    var date = new Date();
    var curDate = null;
    do { curDate = new Date(); }
    while(curDate-date < millis);
}

function unit_temp_n(temperature, full_precision){
  if (isNaN(parseFloat(temperature))) { return ""; }
  if (G_user_setting_temperature == "C")
    if (full_precision)
      return temperature;
    else
      return Math.round(full_precision);
  else if (!full_precision)
    return Math.round((temperature-32)*5/9);
  else
    return (temperature-32)*5/9;
}

function unit_distance_n(distance, full_precision){
  if (G_user_setting_distance == "m" && full_precision)
    return distance;
  else if (G_user_setting_distance == "m")
    return Math.round(distance*10)/10;
  else if (!full_precision)
    return Math.round(distance/3.2808399*10)/10;
  else
    return distance/3.2808399;
}

function unit_weight_n(weight, full_precision){
  if (G_user_setting_weight == "kg" && full_precision)
    return weight;
  else if (G_user_setting_weight == "kg")
    return Math.round(weight*10)/10;
  else if (!full_precision)
    return Math.round(weight/2*10)/10;
  else
    return weight/2;
}

//END HELPERS


var wizard_first_init = true;
var wizard_correct_dive = false;
var wizard_marker_moved = false;
var wizard_galleria = "";
var wizard_galleria_initialized = false;
var wizard_dive_pictures_data = [];
var wizard_dive_pictures_favorite ="";
var initial_spot_id = $("#spot-id").val();
var current_menu = 0;
var wizard_dive_all_summary;
var wizard_dive_selected_summary;
var g_send_plugin_data_xhr = null;
var wizard_no_spot_on_map = false;
var G_wizard_spot_data = [];
var G_dive_fishes_backup = [];
G_wizard_spot_data[1] =  {
  'location': "",
  'location2': "",
  'location3': "",
  'name': "",
  'country_code': "BLANK",
  'lat': 0.00,
  'long': 0.00,
  'zoom': 1.0,
  'precise': false
};

var G_W_model = "";
var G_autodetect_started = 0;
var wizard_maps_loaded = false;
var G_picture_cnt = 1;
var G_tmp_dive_storage = null;
var G_tmp_user_storage = null;

var G_search_pending = null;
var G_search_search_ajax_requests = [];
var geocoder;

//////////////////////////
//
// SEARCH
//
//////////////////////////

function check_init_geocoder() {
  if (!geocoder) {
      try {
        geocoder = new google.maps.Geocoder(); //load geocoder only once
      } catch(e) {}
    }	
}

function search_something(text) {
  if (text == '') {
    $("#xp_p1_search_result ul").html('');
    $("#xp_p1_search_result").hide();
    return;
  }
  check_init_geocoder();
  if (geocoder) {
	  geocoder.geocode(
	      {'address': text},
	      function(results, status) {
	        //Remove the request from the pool and revert the icon if necessary
	        for (var i in G_search_search_ajax_requests)
	          if (G_search_search_ajax_requests[i] == "geocoding request")
	            G_search_search_ajax_requests.splice(i,1);
	        if (G_search_search_ajax_requests.length == 0)
	          $("#search_text_button").attr("src", "/img/black_search_btn.png");
	
	        if (status == google.maps.GeocoderStatus.OK) {
	          var image_url = "/img/world_icon.png";
	          $("#xp_p1_search_result").show();
	          $("#xp_p1_search_result ul").html('');
	          for (var i in results)
	          {
	            //todo put the append outside of the for loop
	            $("#xp_p1_search_result ul").append(
	              $('<li class="xp_p1_search_result"><div class="xp_p1_search_result_letter"></div>'+
	              '<div class="xp_p1_search_result_right"><span class="xp_p1_search_result_name">'+
	              results[i].formatted_address+'</span><span class="xp_p1_search_result_details"></span></div></li>')
	              .data('xp_formatted_address', results[i].formatted_address)
	              .mousedown((function(result) {return function(ev){
	                ev.preventDefault();
	                $('#xp_p1_search').data('xp_search_result', $(this).data('xp_formatted_address'));
	                $('#xp_p1_search').blur();
	                $("#xp_p1_search_result").hide();
	                goto_search_result(result);
	              }})(results[i]))
	            );
	          }
	
	          //initializeLayout();
	
	        } else {
	          //alert("Geocode was not successful for the following reason: " + status);
	        }
	      }
	    );
  	}
}

function goto_search_result(result) {
  var lat = result.geometry.location.lat;
  var lng = result.geometry.location.lng;
  map.fitBounds(result.geometry.viewport);
  
  marker.setMap(map);
  marker.setPosition(result.geometry.location);
  $("#spot-lat").val(lat);
  $("#spot-long").val(lng);
  wizard_correct_dive = true;
  wizard_marker_moved = true;
  $("#wizardgmaps_placepin").hide();
  $("#wizardgmaps_removepin").show();
  $("#spot-zoom").val(map.getZoom());
  reverse_geocode();
}

function clearPositionDelta() {
	if (alternate_position_marker != null) {
		alternate_position_marker.setMap(null);
	}
}

function markPositionDelta(lat, long) {
    var image = new google.maps.MarkerImage('/img/explore/marker_shop.png',
    	      new google.maps.Size(15, 15),
    	      new google.maps.Point(0,0),
    	      new google.maps.Point(7, 7)
    	    );
	var myLatLng = {lat: parseFloat(lat), lng: parseFloat(long)};
	clearPositionDelta();
	alternate_position_marker = new google.maps.Marker({
        position: myLatLng,
        map: map,
        icon: image,
        draggable: false
      });
	reverse_geocode_clear_wait();
}

function markNewPositionDelta(lat, long) {
	if (rever_geocode_debug) {
	    var image = new google.maps.MarkerImage('/img/explore/marker_shop_grey.png',
	    	      new google.maps.Size(15, 15),
	    	      new google.maps.Point(0,0),
	    	      new google.maps.Point(7, 7)
	    	    );
		var myLatLng = {lat: parseFloat(lat), lng: parseFloat(long)};
		clearPositionDelta();
		alternate_position_markers.push(new google.maps.Marker({
	        position: myLatLng,
	        map: map,
	        icon: image,
	        draggable: false
	      }));
	}
}

function clearPositionDeltaMarkers() {
	if (alternate_position_markers!=null) {
		for (var i = 0; i< alternate_position_markers.length; i++) {
			alternate_position_markers[i].setMap(null);
		}
	}
	alternate_position_markers = [];
}

function reverse_geocode_for_deltas(lat, long, deltas, i) {
	if (i>=deltas.length) {
		if (reverse_geocode_latest_result != null) {
			$("#spot-location-1").val(reverse_geocode_latest_result.level1);
			$("#spot-location-2").val(reverse_geocode_latest_result.level2);
			$("#spot-location-3").val(reverse_geocode_latest_result.level3);
			markPositionDelta(reverse_geocode_latest_result.lat, reverse_geocode_latest_result.long);
		} else {
			$("#spot-location-1").val("Unknown");
		}
		clearPositionDelta();
		reverse_geocode_clear_wait();
		return;
	}
	var r_earth = 6371000;
	var d_lat = deltas[i].d_lat;
	var d_long = deltas[i].d_long;
	var new_latitude  = lat  + (d_long / r_earth) * (180 / Math.PI);
	var new_longitude = long + (d_lat / r_earth) * (180 / Math.PI) / Math.cos(lat * Math.PI/180);
	reverse_geocode_for_latlng({lat: parseFloat(new_latitude), lng: parseFloat(new_longitude)}, function (ret_value) {
		if (ret_value.status) {
			if (ret_value.level2 == null || ret_value.level3 == null) {
					//check if the new result is better than the old one
				if (reverse_geocode_latest_result == null || (reverse_geocode_latest_result.level2 == null && ret_value.level2 != null) || (reverse_geocode_latest_result.level3 == null && ret_value.level3 != null)) {
					reverse_geocode_latest_result = ret_value;
					reverse_geocode_latest_result.lat = new_latitude;
					reverse_geocode_latest_result.long = new_longitude;
				}
				markNewPositionDelta(new_latitude, new_longitude);
				reverse_geocode_for_deltas(lat, long, deltas, i+1);
			}
			else {
				$("#spot-location-1").val(ret_value.level1);
				$("#spot-location-2").val(ret_value.level2);
				$("#spot-location-3").val(ret_value.level3);
				markPositionDelta(new_latitude, new_longitude);
			}
    	} else {
    		markNewPositionDelta(new_latitude, new_longitude);
    		reverse_geocode_for_deltas(lat, long, deltas, i+1);
    	}
	});
}

function reverse_geocode_wait() {
    $("#spot-location-1").val("");
    $("#spot-location-2").val("");
    $("#spot-location-3").val("");
    $("#wizard_spot_search #wizard_spot_confirm #wizard_spot_cancel").hide();
    $("#reverse_geeocode_loader").show();
}

function reverse_geocode_clear_wait() {
	$("#wizard_spot_search #wizard_spot_confirm #wizard_spot_cancel").show();
	$("#reverse_geeocode_loader").hide();
}

function reverse_geocode() {
	reverse_geocode_wait();
    var epsilon = 1000;
    var epsilon2 = 5000;
    reverse_geocode_latest_result = null;
    clearPositionDeltaMarkers();
	//Page timeout on the google API limits the options to only explore 4 other positions
    var deltas = [{d_lat:epsilon,d_long:0},{d_lat:-epsilon,d_long:0},{d_lat:0,d_long:epsilon},{d_lat:0,d_long:-epsilon},{d_lat:epsilon,d_long:epsilon},{d_lat:epsilon,d_long:-epsilon},{d_lat:-epsilon,d_long:epsilon},{d_lat:-epsilon,d_long:-epsilon},{d_lat:epsilon2,d_long:0},{d_lat:-epsilon2,d_long:0},{d_lat:0,d_long:epsilon2},{d_lat:0,d_long:-epsilon2},{d_lat:epsilon2,d_long:epsilon2},{d_lat:epsilon2,d_long:-epsilon2},{d_lat:-epsilon2,d_long:epsilon2},{d_lat:-epsilon2,d_long:-epsilon2}];
    //var deltas = [{d_lat:epsilon2,d_long:0},{d_lat:-epsilon2,d_long:0},{d_lat:0,d_long:epsilon2},{d_lat:0,d_long:-epsilon2}];
    var lat = parseFloat($("#spot-lat").val());
    var long = parseFloat($("#spot-long").val());
	if (parseFloat($("#spot-lat").val())!=0 && parseFloat($("#spot-long").val())!=0) {
		reverse_geocode_for_latlng({lat: parseFloat(lat), lng:parseFloat(long)}, function (ret_value) {
			if (ret_value.status) {
				if (ret_value.level2 == null || ret_value.level3 == null) {
					reverse_geocode_latest_result = ret_value;
					reverse_geocode_latest_result.lat = lat;
					reverse_geocode_latest_result.long = long;
					reverse_geocode_for_deltas(lat, long, deltas, 0);
				} else {
					$("#spot-location-1").val(ret_value.level1);
					$("#spot-location-2").val(ret_value.level2);
					$("#spot-location-3").val(ret_value.level3);
					clearPositionDelta();
				}
			} else {
				reverse_geocode_for_deltas(lat, long, deltas, 0);
			}
	    });
	}
}

function reverse_geocode_for_latlng(latlng, callback) {
    var spot_country_code = null;
    var spot_country_name = null;
    var admin_l1 = null;
    var admin_l2 = null;
    var admin_l3 = null;
    var formatted_address = null;
    var locality = null;
    var poi = null;
	check_init_geocoder();
    if (geocoder) {
	    geocoder.geocode({'location': latlng}, function(results, status) {
	      var ret_value = {status:false};
	      if (status == google.maps.GeocoderStatus.OK) {
	        for (var i = 0; i < results.length; i++) {
	          var result = results[i];
	          if (formatted_address == null) {
	        	  formatted_address = result.formatted_address;
	          }
	          for (var j = 0; j < result.address_components.length; j++) {
		          var element = result.address_components[j];
	        	  if (element.types.includes("country") && spot_country_code == null) {
	        		  spot_country_code = element.short_name;
	        		  spot_country_name = element.long_name;
	        	  }
	        	  if (element.types.includes("locality") && locality == null) {
	        		  locality = element.long_name;
	        	  }
	        	  if (element.types.includes("administrative_area_level_1") && admin_l1 == null) {
	        		  admin_l1 = element.long_name;
	        	  }
	        	  if (element.types.includes("administrative_area_level_2") && admin_l2 == null) {
	        		  admin_l2 = element.long_name;
	        	  }
	        	  if (element.types.includes("administrative_area_level_3") && admin_l3 == null) {
	        		  admin_l3 = element.long_name;
	        	  }
	        	  if ((element.types.includes("park") || element.types.includes("point_of_interest")) && poi == null) {
	        		  poi = element.long_name;
	        	  }
	          }
	        }
	        var name1 = null;
	        var name2 = null;
	        var name3 = null;
	        if (spot_country_code != null) {
    		  $("#spot-country").val(spot_country_name);
    		  $("#spot-country").attr("shortname", spot_country_code);
    		  $("#wizard-spot-flag").attr("src","/img/flags/"+spot_country_code.toLowerCase()+".gif");
	        }
	        if (name1 == null && poi != null) {
	        	name1 = poi;
	        	poi = null;
	        }
	        if (name1 == null && locality != null) {
	        	name1 = locality;
	        	locality = null;
	        }
	        if (name1 == null && admin_l1 != null) {
	        	name1 = admin_l1;
	        	admin_l1 = null;
	        }
	        if (name1 == null && formatted_address != null) {
	        	name1 = formatted_address;
	        	formatted_address = null;
	        }
	        if (name2 == null && locality != null) {
	        	name2 = locality;
	        	locality = null;
	        }
	        if (name2 == null && admin_l1 != null) {
	        	name2 = admin_l1;
	        	admin_l1 = null;
	        }
	        if (name2 == null && admin_l2 != null) {
	        	name2 = admin_l2;
	        	admin_l2 = null;
	        }
	        if (name3 == null && admin_l1 != null) {
	        	name3 = admin_l1;
	        	admin_l1 = null;
	        }
	        if (name3 == null && admin_l2 != null) {
	        	name3 = admin_l2;
	        	admin_l2 = null;
	        }
	        if (name3 == null && admin_l3 != null) {
	        	name3 = admin_l3;
	        	admin_l3 = null;
	        }
	        ret_value = {status:true, level1:name1, level2:name2, level3: name3};
	        callback(ret_value);
	      } else if (status == google.maps.GeocoderStatus.OVER_QUERY_LIMIT) {
	    	  sleep(2100);
	    	  return reverse_geocode_for_latlng(latlng, callback);
	      } else {
	    	  callback(ret_value);
	      }
	    });
      }
}
///////////////////////////////
//
// OPENING AND CLOSING WIZARD
//
///////////////////////////////

function hide_wizard(e)
{
  if(e)
    e.preventDefault();

  var current_tab = location.hash.slice(1);
  G_page_fullpermalink = G_page_fullpermalink_backup;
  window.onbeforeunload = null;
  $("#tab_share_link").show();
  $(".editable_form").hide();
  $(".editable").show();
  $(".plain_links").show();

  //reset all the tabs
  $.each(G_wizard_tabs, function(idx, e){
    $(e.elt).css("display", e.display);
    //if(e.active)
    //  $(e.elt).click();
  });
  if( $(".tab_link.active").is(":visible"))
    $(".tab_link.active").click();
  else
    $("#tab_overview_link").click();
  
  $("#wizardgmaps").empty();
  $("#tab_ppl_link").hide();
}

function close_wizard(){
  window.onbeforeunload = null;
  G_page_fullpermalink = G_page_fullpermalink_backup;
  $("#tab_share_link").show();
  $(".plain_links").show();

  if ($("#spot-id").val() != initial_spot_id && ($("#dive-id").val() != "1" && $("#dive-id").val() != "")){
    //we need to reload everything
    location.replace("/"+G_owner_vanity_url+"/"+$("#dive-id").val()+"?updated=true");
  }
  else if ($("#dive-id").val() == "1" || $("#dive-id").val() == "" ) {
    location.replace("/"+G_owner_vanity_url);

  }else{
    $('.window').hide();
    if (G_has_dives) {
      showDive($("#dive-id").val());
    }
    else{
      showDive(0);
    }
  }
}

function show_wizard(e){
  //Cancel the link behavior
  if (e != null){ e.preventDefault(); }

  //prevent backs
  window.onbeforeunload = confirmExit;
  function confirmExit()
  {
    return I18n.t(["js","wizard","You have attempted to leave this page.  If you have made any changes to the fields without clicking the Save button, your changes will be lost.  Are you sure you want to exit this page?"]);
  }

  dive_updated = undefined; // we reset this var
  $(".plain_links").hide();
  $(".editable").hide();
  $(".editable_form").show();

  //Get the screen height and width
  var maskHeight = $(document).height();
  var maskWidth = $(window).width();

  //Set heigth and width to mask to fill up the whole screen
  $('#mask').css({'width':maskWidth,'height':maskHeight});

  /*
  //transition effect
  $('#mask').fadeIn(200);
  $('#mask').fadeTo("fast",0.6);
  $("#mask img").show();
  */

  //show the form
  $("#formedit_dive").show();


  //show all the tabs, but remember which where opened
  $(".tab_link").each(function(index, element) {
    G_wizard_tabs.push({elt: element, display: $(element).css('display'), active: $(element).hasClass("active")});
  });
  $("#tab_share_link").hide();
       if($("#tab_share_link").hasClass("active"))
               {
                       show_overview_tab(null);
               }
  $(".tab_link.editable_tab").show();


  // manage the tabs url change wizardry
  G_page_fullpermalink = G_page_fullpermalink +"/edit";
  var current_tab = location.hash.slice(1);
  if(window.history.pushState){
    var uri_parser = document.createElement("a");
    uri_parser.href = G_page_fullpermalink;
    window.history.pushState("","",uri_parser.pathname+"#"+current_tab);
  }


  // RESET du status
  if(wizard_first_init == true){
    wizard_store_default();
    wizard_store_current_spot();
    set_wizard_bindings();
    wizard_initialize_galleria();
  }
  wizard_first_init = false; //we say that wizard was init once

  //launch the calls for profile right away
  if (G_has_profile) wizard_profile_display();

  //Get the A tag
  var id = $(this).attr('href');


  //set default values if any
  wizard_reset_default();

  try {
    $('a.add_own_gear').live('click', own_new_gear);
    $('.data_gear').each(function(idx, elt) { $(elt).data('diveboard_gear_wizard', JSON.parse($('<div></div>').html($(elt).attr('data-diveboard_gear_wizard')).text()  ) )  });
  } catch(e){
    track_exception_global(e);
  }

  $("#spot-id").val(G_dive_spot_id_nil);

  //setup the file uploader
  try {
    setup_upload_udcf_file();
  } catch(e){
    track_exception_global(e);
  }

  //setup the picture uploader
  try {
    setup_upload_pictures();
  } catch(e){
    track_exception_global(e);
  }

  $("#tab_ppl_link").show();

  $("#share_close").click(function (e) {
    if (e != null) e.preventDefault();
    $('#diveboard_share_menu').hide();
    $('#share_mask').hide();
  });

  init_species_picker();
  initialize_dive_review();

}


function set_wizard_bindings(){
  $('.tooltiped-wz').qtip({
    style: {
      tip: { corner: true },
      classes: "ui-tooltip-diveboard"
    },
    position: {
      at: "bottom center",
      my: "top right"
    }
  });

//NAVIGATION

  $("#fb_post_button").click(check_fb_post_to_wall_perms);
  $(".wizard_save").click(wizard_save_close);
  if ( $("#dive-id").val() == "" )
    $(".wizard_cancel").click( function(e){ if (e) e.preventDefault(); location.replace("/" + G_owner_vanity_url);} );
  else
    $(".wizard_cancel").click(hide_wizard);
  $(".delete_dive").click(delete_dive);

//SEARCH LOCATION
  //2 behaviours for people who want to click on the icon instead of the list...
  $('#xp_p1_search_button').click(function(ev) {
    if ($("#xp_p1_search_result ul li:visible").length == 1) {
      $("#xp_p1_search_result ul li").mousedown();
    }
    else {
      if (G_search_pending) clearTimeout(G_search_pending);
      G_search_pending = null;
      search_something($('#xp_p1_search').val());
    }
  });

  $('#xp_p1_search').focus(function(e) {
    var text = $('#xp_p1_search').data('xp_search_text');
    if (text) {
      $('#xp_p1_search').val(text);
    }

    if ($("#xp_p1_search_result ul li").length > 0)
      $("#xp_p1_search_result").show();
  });

  $('#xp_p1_search').blur(function(e) {
    $('#xp_p1_search').data('xp_search_text', $('#xp_p1_search').val());
    var result = $('#xp_p1_search').data('xp_search_result');
    if (result) {
      $('#xp_p1_search').val(result);
    }
    setTimeout(function(){$("#xp_p1_search_result").hide()}, 100);
  });

  $(document).bind('keydown', function(ev) {
    if ($('#xp_p1_search').is(':focus')) return;
    //This shortcut is commented because it didn't help and was blocking some tests
    //Press F key to activate search
    //not available when focus is on an input field
    //if (ev.which == 70 && $("input:focus").length == 0) {
    //  $('#xp_p1_search').focus();
    //  ev.preventDefault();
    //}

    // - for zoom out, + or = for zoom in
    else if (ev.which == 189) {
      map.setZoom(map.getZoom()-1);
      ev.preventDefault();
    }
    else if (ev.which == 187) {
      map.setZoom(map.getZoom()+1);
      ev.preventDefault();
    }

    //enter or right arrow shows the second panel
    else if(ev.which == 13 || ev.which == 39) { //enter
      if ($("#xp_p1_tab li.xp_panel_list_item.selected").length > 0) {
        $("#xp_p1_tab li.xp_panel_list_item.selected").click();
        ev.preventDefault();
      }
    }

    //left arrow hides the second panel
    else if(ev.which == 37) { //enter
      if ($("#xp_p1_tab li.xp_panel_list_item.selected").length > 0) {
        hide_panel2();
        ev.preventDefault();
      }
    }



    //up/down arrows make selection go next/forward in panel 1
    else if (ev.which == 38) { //up
      ev.preventDefault();
      var sel;
      var list = $("#xp_p1_tab li");
      for (var i=0;i<list.length; i++) {
        var e=$(list[i]);
        if (e.hasClass('selected')) {
          e.removeClass('selected');
          if (i)
            sel = $(list[i-1]).addClass('selected');
          else
            sel = list.last().addClass('selected');
          $("#xp_p1_list").data('jsp').scrollToElement(sel);
          return;
        }
      }
      sel = list.last().addClass('selected');
      $("#xp_p1_list").data('jsp').scrollToElement(sel);
    } else if (ev.which == 40) { //down
      ev.preventDefault();
      ev.stopPropagation();
      var sel;
      var list = $("#xp_p1_tab li");
      for (var i=0;i<list.length; i++) {
        var e=$(list[i]);
        if (e.hasClass('selected')) {
          e.removeClass('selected');
          sel = $(list[(i+1)%(list.length)]).addClass('selected');
          $("#xp_p1_list").data('jsp').scrollToElement(sel);
          return;
        }
      }
      sel = list.first().addClass('selected');
      $("#xp_p1_list").data('jsp').scrollToElement(sel);
    }
  });

  $('#xp_p1_search').bind('keyup', function(e) {

    //on enter, either launch a search or click on the elected element
    if(e.which == 13) { //enter
      if (G_search_pending) clearTimeout(G_search_pending);
      G_search_pending = null;
      if ($("#xp_p1_search_result_list li.selected").length > 0)
        $("#xp_p1_search_result_list li.selected").removeClass('selected').mousedown();
      else
        search_something($('#xp_p1_search').val());

    //escape to blur search
    } else if (e.which == 27) { //escap
      $('#xp_p1_search').blur();

    //up/down arrows make selection go next/forward
    } else if (e.which == 38) { //up
      e.preventDefault();
      var sel;
      var list = $("#xp_p1_search_result_list li");
      for (var i=0;i<list.length; i++) {
        var e=$(list[i]);
        if (e.hasClass('selected')) {
          e.removeClass('selected');
          if (i)
            sel = $(list[i-1]).addClass('selected');
          else
            sel = list.last().addClass('selected');
          $("#xp_p1_search_result").data('jsp').scrollToElement(sel);
          return;
        }
      }
      sel = list.last().addClass('selected');
      $("#xp_p1_search_result").data('jsp').scrollToElement(sel);
    } else if (e.which == 40) { //down
      e.preventDefault();
      var sel;
      var list = $("#xp_p1_search_result_list li");
      for (var i=0;i<list.length; i++) {
        var e=$(list[i]);
        if (e.hasClass('selected')) {
          e.removeClass('selected');
          sel = $(list[(i+1)%(list.length)]).addClass('selected');
          $("#xp_p1_search_result").data('jsp').scrollToElement(sel);
          return;
        }
      }
      sel = list.first().addClass('selected');
      $("#xp_p1_search_result").data('jsp').scrollToElement(sel);

    //any other key : trigger a search later
    } else {
      $('#xp_p1_search').data('xp_search_result', null);
      $("#xp_p1_search_result_list li.selected").removeClass('selected');
      if (G_search_pending) clearTimeout(G_search_pending);
      G_search_pending = setTimeout(function(){G_search_pending = null; search_something($('#xp_p1_search').val())}, 300);
    }
  });

  $("#xp_p1_search_result_list li").live('hover', function(ev){
    $("#xp_p1_search_result_list li.selected").removeClass('selected');
    $(this).addClass('selected');
  });




//wizard STEP 1 -- SPOT
  $('#wizard_spot_creaspot').click(function(){
    select_spot(1);
    $("#spot-lat").val("");
    $("#spot-long").val("");
    $("#spot-location-1").val("");
    $("#spot-location-2").val("");
    $("#spot-location-3").val("");
    wizard_spot_make_changeable(true);
    map.setCenter(new google.maps.LatLng(0,0));
    map.setZoom(1);
    marker.setMap(null);
    $('#wizard_search_spot').hide();
    $("#wizard_spot_modspot, #wizard_spot_remove, #wizard_spot_confirm").hide();
    $("#wizard_spot_creaspot, #wizard_spot_reset").hide();
    $("#xp_p1_search, #xp_p1_search_button").show();
    $("#wizard_spot_cancel, #wizard_spot_search").css("display", "inline-block");
  });
  $("#wizard_spot_modspot").click(function(){
    wizard_spot_make_changeable(true);
    $('#wizard_search_spot').hide();
    $("#wizard_spot_modspot, #wizard_spot_remove").hide();
    $("#wizard_spot_creaspot, #wizard_spot_reset").hide();
    $("#xp_p1_search, #xp_p1_search_button").show();
    $("#wizard_spot_confirm, #wizard_spot_cancel, #wizard_spot_search").css("display", "inline-block");
  });
  $('#wizard_spot_remove').click(function(){
    select_spot(1);
  });
  $('#wizard_spot_reset').click(function(){
    reset_spot_details();
  });
  $('#wizard_spot_search').click(function(){
    if( wizard_spot_datacheck()==false ){
        diveboard.notify(I18n.t(["js","wizard","Spot parameters"]), I18n.t(["js","wizard","ERROR: Cannot Save. Please correct the fields highlighted in red"]));
        return;
    }
    $("#wizard_simmilar_spots_loader").show();
    $("#wizard_simmilar_spots_label").show();
    $("#wizard_simmilar_spots").html("");
    $("#wizard_simmilar_spots").hide();
    $("#xp_p1_search, #xp_p1_search_button").hide();
    $("#wizard_spot_confirm").show();
	wizard_gmaps_simmilar_highlightspotclear();
	wizard_gmaps_clear_simmilar_spots();
	$("#spot-zoom").val(map.getZoom());
    $.ajax({
        url: '/api/search/simmilarspot',
        data: {n: $("#spot-name").val(), lat:$("#spot-lat").val(), long:$("#spot-long").val(), z:$("#spot-zoom").val()},
        success: function(data){
        	$("#wizard_simmilar_spots_loader").hide();
        	spots = $.map(data.data, function(item){return {label: item.name , value: item.name, id: item.id, lat: item.data.lat, lng: item.data.lng } })
        	if (spots.length>0){
	        	res = "<table style='border:0' class='spot_simmilar'>";
	        	spots.forEach(function(element) {
	        		res += "<tr onmouseover='wizard_gmaps_simmilar_highlightspot("+element.lat+","+element.lng+")' onmouseout='wizard_gmaps_simmilar_highlightspotclear()' onClick='select_spot("+element.id+")'><td>"+element.label+"</td><td><button class='yellow_button' onClick='select_spot("+element.id+")'>"+I18n.t(["js","wizard","Select"])+"</button></td></tr>";
		        	wizard_gmaps_simmilar_spots(element.lat, element.lng, element.id);
	        	});
	        	res += "</table>";
	        	$("#wizard_simmilar_spots").html(res);
        	} else {
        		$("#wizard_simmilar_spots").html(I18n.t(["js","wizard","No simmilar spot found. You can create one."]));
        	}
        	$('#wizard_spot_confirm').show();
        	$("#wizard_simmilar_spots").show();
        }
      });
  });
  $('#wizard_spot_confirm').click(function(){
    if( wizard_spot_datacheck()==false ){
      diveboard.notify(I18n.t(["js","wizard","Spot parameters"]), I18n.t(["js","wizard","ERROR: Cannot Save. Please correct the fields highlighted in red"]));
      return;
    }
    if (confirm(I18n.t(["js","wizard","Do you confirm the spot is not available?"]))) {
	    wizard_spot_make_changeable(false);
	    $('#wizard_search_spot').hide();
	    $("#wizard_simmilar_spots_label, #wizard_simmilar_spots, #wizard_simmilar_locations").hide();
	    $("#wizard_spot_modspot, #wizard_spot_remove").css("display", "inline-block");
	    $("#wizard_spot_creaspot").css("display", "inline-block");
	    if (G_dive_spot_id == 1)
	      $("#wizard_spot_reset").hide();
	    else
	      $("#wizard_spot_reset").css("display", "inline-block");
	    $("#wizard_spot_confirm, #wizard_spot_cancel, #wizard_spot_search, #wizard_simmilar_spots_label, #wizard_simmilar_spots").hide();
	    $("#xp_p1_search, #xp_p1_search_button").hide();
    }
  });
  $('#wizard_spot_cancel').click(function(){
    select_spot($("#spot-id").val());
    $("#wizard_simmilar_spots_label").hide();
    $("#wizard_simmilar_spots").hide();
    $("#wizard_simmilar_locations").hide();
    $("#xp_p1_search, #xp_p1_search_button").hide();
    wizard_gmaps_clear_simmilar_spots();
  });

  $("#wizardgmaps_placepin").click(function(){
      var center = map.getCenter();
      marker.setMap(map);
      marker.setPosition(center);
      $("#spot-lat").val(center.lat());
      $("#spot-long").val(center.lng());
      wizard_correct_dive = true;
      wizard_marker_moved = true;
      $("#wizardgmaps_placepin").hide();
      $("#wizardgmaps_removepin").show();
      $("#spot-zoom").val(map.getZoom());
  });

  $("#wizardgmaps_removepin").click(function(){
      marker.setMap(null);
      $("#spot-lat").val("");
      $("#spot-long").val("");
      wizard_correct_dive = true;
      wizard_marker_moved = false;
      $("#wizardgmaps_placepin").show();
      $("#wizardgmaps_removepin").hide();
      $("#spot-location-1").val("");
      $("#spot-location-2").val("");
      $("#spot-location-3").val("");
  });

  $("#spot-country").change(function(){update_gmaps_from_wizard_edit(false);});
  $("#spot-lat").change(function(){update_gmaps_from_wizard_edit(true);});
  $("#spot-long").change(function(){update_gmaps_from_wizard_edit(true);});

  $("input").live('change',function(){
    if ($(this).attr('type') != 'number')
      return;
    var val = $(this).val();
    var min = $(this).attr('min');
    var max = $(this).attr('max');
    if (val == "") return;
    if (typeof min != 'undefined' && min > val)
      $(this).val(min);
    if (typeof max != 'undefined' && max < val)
      $(this).val(max);
  });

  $('.custom_airmix .o2, .custom_airmix .he').die('keyup');
  $('.custom_airmix .n2').die('change');
  $('.scuba_tank .gas').die('change');
  $('.custom_airmix .o2, .custom_airmix .he').live('keyup', function(){
    update_n2_from_others($(this).closest('.custom_airmix'));
  });
  $('.custom_airmix .n2').live('change', function(){
    $(this).closest('.custom_airmix').data('customised_n2', true);
  });
  $('.scuba_tank .gas').live('change', function(){
    var custom_airmix = $(this).parent().find('.custom_airmix');
    var value = this.options[this.selectedIndex].value;
    if (value == 'air'){
      custom_airmix.hide();
      custom_airmix.find('.o2').val(21);
      custom_airmix.find('.he').val(0);
      custom_airmix.find('.n2').val(79);
    } else if (value == 'trimix') {
      custom_airmix.show();
      custom_airmix.find('.he_input').show();
      custom_airmix.find('.o2').val(21);
      custom_airmix.find('.he').val(0);
      custom_airmix.find('.n2').val(79);
    } else if (value == 'nitrox') {
      custom_airmix.show();
      custom_airmix.find('.he_input').hide();
      custom_airmix.find('.o2').val(21);
      custom_airmix.find('.he').val(0);
      custom_airmix.find('.n2').val(79);
    }
  });

//wizard STEP 2
  //$("#wizard_upload_btn").click($("#file").click());
  $("#wizard_delete_graph").click(delete_profile_data);
  setup_upload_udcf_file();
  $("#dive_list_selector_button").click(get_profile_from_file);
  $("#dive_list_selector_button_cancel").click(wizard_plugin_cancel);
  $("#wizard_import_btn").click(wizard_computeragent_load);
  $("#callMovescountPopup").tclick(movescount_popup);
  $("#importMovescountDives").click(get_profile_from_movescount);
  $("#wizard_plugin_detect_extract").click(plugin_detect_and_extract);
  $("#wizard_plugin_force_extract").click(plugin_force_extract);
  $("#wizard_plugin_install_retry1").click(wizard_plugin_retry);
  $("#wizard_plugin_install_retry2").click(wizard_plugin_retry);
  $("#wizard_plugin_install_cancel1").click(wizard_plugin_cancel);
  $("#wizard_upload_cancel").click(wizard_plugin_cancel);
  $("#wizard_plugin_install_cancel2").click(wizard_plugin_cancel);
  $("#wizard_plugin_install_cancel3").click(wizard_plugin_cancel);
  $("#wizard_plugin_install_cancel4").click(wizard_plugin_cancel);
  try {
    $("#wizard-date").datepicker({
      dateFormat: 'yy-mm-dd',
      changeMonth: true,
      changeYear: true,
      yearRange: '-100:+1',
      onClose: function(dateText, inst) {
        if (!dateText.match(/[0-9]{4}-[0-9]{2}-[0-9]{2}/)){
          $("#wizard-date").val("");
          }
        }
      });
    $.datepicker.setDefaults($.datepicker.regional[$("html").attr("lang") || 'en']);

    $(".dan_date").datepicker({
      dateFormat: 'yymmdd',
      changeMonth: true,
      changeYear: true,
      yearRange: '-100:+1',
      onClose: function(dateText, inst) {
        if (!dateText.match(/^[0-9]{8}$/) || !isDate(dateText.substr(0,4)+'-'+dateText.substr(4,2)+'-'+dateText.substr(6,2)) ){
          $(this).val("");
          }
        }
      });
  } catch(e){ //causes errors on local environment without net
  }
  $("#wizard_computer_select1").change(wizard_computer_show_instructions);
  $("#wizard_computer_select2").change(wizard_computer_show_instructions);
  $("#addsafetystops").click(add_safety_stop);
  $("#wizard-duration-mins").change(divecomplete);
  $("#wizard-max-depth").change(divecomplete);



//wizard STEP 3 - PEOPLE
  $("#wz_shop_create").live('click',function(ev){
    ev.preventDefault();
    $("#wz_shop_found_id").val('');
    $(".wz_shop_line_found").hide();
    $(".wz_shop_line_search").hide();
    $(".wz_shop_line_create").show();
    $('.wz_shop_line_create input').attr('readonly', false);
    $('.wz_shop_line_create input').css('background-color','');
    $("#wz_shop_create_confirm").show();
  });
  $("#wz_shop_change").live('click',function(ev){

    ev.preventDefault();
    $("#wz_shop_found_id").val('');
    $(".wz_shop_line_found").hide();
    $(".wz_shop_line_search").show();
    $(".wz_shop_line_create").hide();
    $('.wz_shop_line_create input').attr('readonly', false);
    $('.wz_shop_line_create input').css('background-color','');
    $("#diveshop-search").val('');
    $("#signing_shop_request").attr("READONLY","readonly").prop("checked", false);
  });
  $("#wz_shop_create_cancel").live('click',function(ev){
    ev.preventDefault();
    $("#wz_shop_found_id").val('');
    $(".wz_shop_line_found").hide();
    $(".wz_shop_line_search").show();
    $(".wz_shop_line_create").hide();
    $('.wz_shop_line_create input').attr('readonly', false);
    $('.wz_shop_line_create input').css('background-color','');
    $("#diveshop-search").val('');
    $("#wz_shop_create_confirm").show();
    $("#signing_shop_request").attr("READONLY","readonly").prop("checked", false);
  });
  $("#wz_shop_create_confirm").live('click',function(ev){
    ev.preventDefault();
    $("#wz_shop_found_id").val('');
    $('.wz_shop_line_create input').attr('readonly', true);
    $('.wz_shop_line_create input').css('background-color','#bbb');
    $("#wz_shop_create_confirm").hide();
    $("#signing_shop_request").removeAttr("READONLY").prop("checked", true);
  });

  $(".wizard_leave_review").die('click');
  $(".wizard_leave_review").live('click', function(ev){
    load_review_form($(".wz_shop_home").attr('href'));
  });

  $(".past_buddies li").click(function(){add_past_buddy($(this))});
  $("#addbuddy").live('click',add_buddy);
  $(".remove_buddy").live('click', remove_buddy);
  $("#signing_shop_request").live(
    'click',
    function(e){
      if($("#signing_shop_request").attr("READONLY") == "readonly") {
        e.preventDefault();
        diveboard.notify(
          I18n.t(["js","wizard","Missing shop"]),
          I18n.t(["js","wizard","You need to select the dive center you dived with in order to allow your dive to be signed"])
        );
        $("#signing_shop_request").prop("checked", false);
      }
    }
  );


//wizard STEP 4

//wizzard STEP 5
  $("#wizard_add_pict_button").click(wizard_add_picture);
  $('#wizard_pict_url').keypress(function(event){if (event.which ==13) wizard_add_picture();});
  $("#wizard_pict_set_fave").click(set_favorite_picture);
  $("#wizard_pict_delete").click(del_current_image);

  $("#wizard-picture-list .picture_minipicker").live('click', function(ev){
    ev.preventDefault();
    create_species_minipicker(this);
  });



  $("#add_gear_button").click(add_new_gear);
  $("#storage_subscribe_action").click(function(e){if(e) e.preventDefault(); paypal_start($("#storage_subscribe").val(), $("#storage_subscribe_donation").val());});

//DAN export
  $('.dan_field, .dan_combo_field').live('blur', function(ev){ check_dan_form_status(G_current_private_dive['dan_data'], G_current_private_dive['dan_data_sent'], false); });
  $('select.dan_field, select.dan_combo_field').live('change', function(ev){ check_dan_form_status(G_current_private_dive['dan_data'], G_current_private_dive['dan_data_sent'], false); });
  $('#dan_allow_update').live('click', function(ev){
    ev.preventDefault();
    G_current_private_dive['dan_data'] = G_current_private_dive['dan_data_sent'];
    check_dan_form_status(G_current_private_dive['dan_data'], G_current_private_dive['dan_data_sent'], false);
  });
  $('#dan_reset_update').live('click', function(ev){
    ev.preventDefault();
    G_current_private_dive['dan_data'] = null;
    hash_to_dan_form(G_current_private_dive['dan_data_sent'], $('.dan_form'));
    check_dan_form_status(G_current_private_dive['dan_data'], G_current_private_dive['dan_data_sent'], false);
  });
  $('.dan_field[name="altitude_exposure"]').live('change', function(ev) {
    if ( $(this).val() == 6 || $(this).val() == '') {
      $('.dan_field[name="altitude_interval"]').closest('li').hide();
      $('.dan_field[name="altitude_date"]').closest('li').hide();
      $('.dan_field[name="altitude_length"]').closest('li').hide();
      $('.dan_field[name="altitude_value"]').closest('li').hide();
    }
    else {
      $('.dan_field[name="altitude_interval"]').closest('li').show();
      $('.dan_field[name="altitude_date"]').closest('li').show();
      $('.dan_field[name="altitude_length"]').closest('li').show();
      $('.dan_field[name="altitude_value"]').closest('li').show();
    }
  });
  $('.dan_field[name="hyperbar"]').live('change', function(ev) {
    if ( $(this).val() == 1 ) {
      $('.dan_field[name="hyperbar_location"]').closest('li').show();
      $('.dan_field[name="hyperbar_number"]').closest('li').show();
    }
    else {
      $('.dan_field[name="hyperbar_location"]').closest('li').hide();
      $('.dan_field[name="hyperbar_number"]').closest('li').hide();
    }
  });

  $("#mask img").hide();
  ga('send', 'event', 'Wizard', 'Edit wizard display');
}

function bulk_wizard_set_ui()
{
  //Step export
  $('.bulk_list_expand').live('click', function(ev) {
    if (ev)
      ev.preventDefault();

    $(".export_list_item").css('height', '');
    $(".export_list_item").removeClass('export_list_item_folded');
    $(".export_list_item .exitem_switch img").attr('src', '/img/folding_down.png');
  });
  $('.bulk_list_fold').live('click', function(ev) {
    if (ev)
      ev.preventDefault();
    $(".export_list_item").css('height', '');
    $(".export_list_item").addClass('export_list_item_folded');
    $(".export_list_item .exitem_switch img").attr('src', '/img/folding_left.png');
  });

  $("#wizard_export_list :checkbox").shiftcheckbox();


  $("#exitem_view_class").live('change', function(ev) {
    if (ev) ev.preventDefault();

    $(".export_list_item_view0").removeClass('export_list_item_view0');
    $(".export_list_item_view1").removeClass('export_list_item_view1');
    $(".export_list_item_view2").removeClass('export_list_item_view2');
    $(".export_list_item_view3").removeClass('export_list_item_view3');
    $(".export_list_item_view4").removeClass('export_list_item_view4');
    $(".export_list_item_view5").removeClass('export_list_item_view5');
    $(".export_list_text_container").addClass($(this).val());
  });


  $("#apply_bulk_action").live('click', function(ev) {
    if (ev)
      ev.preventDefault();
    var action = $("#wizard_export_action").val();
    $("#wizard_export_action option:first").attr('selected','selected');

    //First make sure some dive has been selected
    if ($("#wizard_export_list input:checked").length == 0) {
      $( "#dialog-bulk-noneselected" ).dialog({
        resizable: false,
        modal: true,
        zIndex: 99999,
        buttons: {
          "OK": function() {
            $( this ).dialog( "close" );
          }
        }
      });
      $(".ui-dialog").position({
   my: "center",
   at: "center",
   of:".ui-widget-overlay"
});
      return;
    }

    //OK now you're talking.... saying what ?
    switch(action)
    {
      case 'wizard_export_zxl':
          request_export_zxl();
          break;
      case 'wizard_export_udcf':
          request_export_udcf();
          break;
      case 'wizard_bulk_print':
          $("#bulk_print_format").val("a5-2");
          $("#bulk_print_pictures").val("-1");
          $("#wizard_bulk_print_div .bulk_editor_warn span").html($("#wizard_export_list input:checked").length);
          $('#wizard_bulk_print_div').show();
          $('#bulk_wizard_tab').hide();
          break;
      case 'wizard_bulk_public':
          request_bulk_public();
          break;
      case 'wizard_bulk_private':
          request_bulk_private();
          break;
      case 'wizard_bulk_fb_timeline':
          request_bulk_fb_timeline();
          break;
      case 'wizard_bulk_delete':
          request_bulk_delete();
          break;

      case 'wizard_bulk_trip':
          var vals = G_all_dive_data[$("#wizard_export_list input:checked").first().attr('name')]['trip_name'];
          var has_different_vals = false;
          $("#wizard_export_list input:checked").each(function(idx, value) {
            has_different_vals = has_different_vals || (vals != G_all_dive_data[value.name]['trip_name']);
          });
          if (has_different_vals)
            $('#wizard_bulk_trip_div .bulk_editor_warn').show();
          else
            $('#wizard_bulk_trip_div .bulk_editor_warn').hide();
          $('#wizard-trip').removeClass('example');
          $('#wizard-trip').val(vals);
          $('#wizard-trip').blur();
          $('#wizard_bulk_trip_div').show();
          $('#bulk_wizard_tab').hide();
          break;
      case 'wizard_bulk_water':
          var vals = G_all_dive_data[$("#wizard_export_list input:checked").first().attr('name')]['water'];
          var has_different_vals = false;
          $("#wizard_export_list input:checked").each(function(idx, value) {
            has_different_vals = has_different_vals || (vals != G_all_dive_data[value.name]['water']);
          });
          if (has_different_vals)
            $('#wizard_bulk_water_div .bulk_editor_warn').show();
          else
            $('#wizard_bulk_water_div .bulk_editor_warn').hide();
          $('#water').val(vals);
          $('#wizard_bulk_water_div').show();
          $('#bulk_wizard_tab').hide();
          break;
      case 'wizard_bulk_visibility':
          var vals = G_all_dive_data[$("#wizard_export_list input:checked").first().attr('name')]['visibility'];
          var has_different_vals = false;
          $("#wizard_export_list input:checked").each(function(idx, value) {
            has_different_vals = has_different_vals || (vals != G_all_dive_data[value.name]['visibility']);
          });
          if (has_different_vals)
            $('#wizard_bulk_visibility_div .bulk_editor_warn').show();
          else
            $('#wizard_bulk_visibility_div .bulk_editor_warn').hide();
          $('#wizard-visibility').val(vals);
          $('#wizard_bulk_visibility_div').show();
          $('#bulk_wizard_tab').hide();
          break;
      case 'wizard_bulk_altitude':
          var vals = G_all_dive_data[$("#wizard_export_list input:checked").first().attr('name')]['altitude'];
          var has_different_vals = false;
          $("#wizard_export_list input:checked").each(function(idx, value) {
            has_different_vals = has_different_vals || (vals != G_all_dive_data[value.name]['altitude']);
          });
          if (has_different_vals)
            $('#wizard_bulk_altitude_div .bulk_editor_warn').show();
          else
            $('#wizard_bulk_altitude_div .bulk_editor_warn').hide();
          $('#altitude').val(vals);
          $('#wizard_bulk_altitude_div').show();
          $('#bulk_wizard_tab').hide();
          break;
      case 'wizard_bulk_buddy':
          var vals = G_all_dive_data[$("#wizard_export_list input:checked").first().attr('name')]['legacy_buddies_hash'];
          var has_different_vals = false;
          $("#wizard_export_list input:checked").each(function(idx, value) {
            has_different_vals = has_different_vals || (JSON.stringify(vals) != JSON.stringify(G_all_dive_data[value.name]['buddy']));
          });
          if (has_different_vals)
            $('#wizard_bulk_buddy_div .bulk_editor_warn').show();
          else
            $('#wizard_bulk_buddy_div .bulk_editor_warn').hide();

          $('.edit_buddy_list').html('');
          $.each(vals, function(idx, buddy) { //TODO BUDDIES
            var where = "";
            var picturl = buddy['picturl'];
            if (buddy['db_id'] > 0 )
              where = "Diveboard";
            else if (buddy['fb_id'] > 0){
              where = "Facebook";
              picturl = "https://graph.facebook.com/v2.0/"+buddy['fb_id']+"/picture?type=square";
            }else{
              where = "Email"
            }
            if (picturl == null || picturl == "")
              picturl = "/img/no_picture.png";

            var input = $('<input type=hidden />');
            $.each(buddy, function(name, val) {
              input.attr(name, val);
            });

            var elt = $("<li class='buddy'><img src='"+picturl+"' class='buddy_picker_list'/><span class='buddy_picker_list_span'>" + buddy['name'] + " "+I18n.t(["js","wizard","via"])+" "+where+" <a href='#' class='remove_buddy'>"+I18n.t(["js","wizard","Remove Buddy"])+"</a></span></li>");
            elt.prepend(input);

            $('.edit_buddy_list').append(elt);
          });

          $('#buddy_count').text(vals.length);

          $('#wizard_bulk_buddy_div').show();
          $('#bulk_wizard_tab').hide();
          break;
      case 'wizard_bulk_shop':
          //We start by resettign the fields
          $("#wz_shop_found_id").val('');
          $("#wz_shop_found_name").text('');
          $("#wz_shop_found_url").attr("href", "");
          $("#wz_shop_found_url").text("");
          $("#signing_shop_request").attr("READONLY", "READONLY").removeAttr("CHECKED");
          $("#guide").val('');
          //then we can do some work
          var dive_vals = G_all_dive_data[$("#wizard_export_list input:checked").first().attr('name')];
          var vals = G_all_dive_data[$("#wizard_export_list input:checked").first().attr('name')]['diveshop'];
          var has_different_vals = false;
          $("#wizard_export_list input:checked").each(function(idx, value) {
            has_different_vals = has_different_vals || (JSON.stringify(vals) != JSON.stringify(G_all_dive_data[value.name]['diveshop']));
            if (vals == null)
              vals = G_all_dive_data[value.name]['diveshop'];
          });
          if (has_different_vals)
            $('#wizard_bulk_shop_div .bulk_editor_warn').show();
          else
            $('#wizard_bulk_shop_div .bulk_editor_warn').hide();

          try {
            $("#guide").val(dive_vals['guide']);
            if (vals['name']) {
              if (dive_vals['shop_id']){
                $("#wz_shop_found_id").val(dive_vals['shop_id']);
                $("#signing_shop_request").removeAttr("READONLY").removeAttr("CHECKED");

              }
              else {
                $("#wz_shop_found_id").val('');
              }
              $(".wz_shop_line_create input").val('');
              $(".wz_shop_line_found").show();
              $(".wz_shop_line_search").hide();
              $(".wz_shop_line_create").hide();
              $('.wz_shop_line_create input').attr('readonly', false);
              $('.wz_shop_line_create input').css('background-color','');
              $("#diveshop-search").val('');
              $("#wz_shop_found_name").text(vals['name']);
              if(vals['url']!=null){
              $("#wz_shop_found_url").text(vals['url']);
              $("#wz_shop_found_url").attr('href', vals['url']);
            }
              $("#diveshop-name").text(vals['name']);
              $("#diveshop-country").text(vals['country']);
              $("#diveshop-town").text(vals['town']);
              $("#diveshop-url").text(vals['url']);
            } else {
              $("#wz_shop_found_id").val('');
              $(".wz_shop_line_create input").val('');
              $(".wz_shop_line_found").hide();
              $(".wz_shop_line_search").show();
              $(".wz_shop_line_create").hide();
              $('.wz_shop_line_create input').attr('readonly', false);
              $('.wz_shop_line_create input').css('background-color','');
              $("#diveshop-search").val('');
            }
          } catch (e) {}

          $('#wizard_bulk_shop_div').show();
          $('#bulk_wizard_tab').hide();
          break;
      case 'wizard_bulk_signature':
          bulk_request_signature();
          break;
      case 'wizard_bulk_location':
          var vals = G_all_dive_data[$("#wizard_export_list input:checked").first().attr('name')]['spot_id'];
          var has_different_vals = false;
          $("#wizard_export_list input:checked").each(function(idx, value) {
            has_different_vals = has_different_vals || (JSON.stringify(vals) != JSON.stringify(G_all_dive_data[value.name]['spot_id']));
          });
          if (has_different_vals)
            $('#wizard_bulk_location_div .bulk_editor_warn').show();
          else
            $('#wizard_bulk_location_div .bulk_editor_warn').hide();
          G_dive_spot_id = parseInt(vals);
          select_spot(parseInt(vals));
          $('#wizard_bulk_location_div').show();
          $('#bulk_wizard_tab').hide();
          break;
      case 'wizard_bulk_gear':
          var vals = G_all_dive_data[$("#wizard_export_list input:checked").first().attr('name')]['gears'];
          var has_different_vals = false;
          $("#wizard_export_list input:checked").each(function(idx, value) {
            has_different_vals = has_different_vals || (JSON.stringify(vals) != JSON.stringify(G_all_dive_data[value.name]['gears']));
          });
          if (has_different_vals)
            $('#wizard_bulk_gear_div .bulk_editor_warn').show();
          else
            $('#wizard_bulk_gear_div .bulk_editor_warn').hide();

          $('.gear_wizard_table .data_gear').detach();
          $.each(vals, function(i,e){
            var item = add_gear(e, $('.gear_wizard_table'));
            if (e['class'] == 'DiveGear')
              item.append( '<td><a href="#" class="add_own_gear">'+I18n.t(["js","wizard","I own it"])+'</a></td>');
          });

          $('#wizard_bulk_gear_div').show();
          $('#bulk_wizard_tab').hide();
          break;
          case 'wizard_bulk_numbering':
          $("#wizard_bulk_numbering_data").empty();
          $("#wizard_bulk_numbering_data_ext").attr("value",$("#wizard_bulk_numbering_data_ext").attr("def"));
            $("#wizard_export_list input:checked").each(function(idx, value) {
              $("#wizard_bulk_numbering_data").append( $("#wizard_bulk_numbering_template").find("li[name='"+value.name+"']").clone())
            })
            $('#wizard_bulk_numbering_div').show();
            $('#bulk_wizard_tab').hide();
          break;
      default:
          var actions = {};
          actions[I18n.t(["js","wizard","OK"])] = function() { $(this).dialog( "close" ) };
          $( "#dialog-bulk-noactionselected" ).dialog({
              resizable: false,
              modal: true,
              zIndex: 99999,
              buttons: actions
            });
          $(".ui-dialog").position({
   my: "center",
   at: "center",
   of:".ui-widget-overlay"
});
          break;
    }
  });
  $(".wizard_bulk_cancel").live('click', function(ev){
    if (ev)
      ev.preventDefault();
    $('.bulk_editor_div').hide();
    $('#bulk_wizard_tab').show();
    //$('.wizard_export_checkbox').attr('checked', false);
  });

  $('.export_list_item a').live('click', function(ev){ev.stopPropagation();});
  $('.wizard_export_checkbox').live('click', function(ev){ev.stopPropagation();});
  $(".export_list_item").live('click', function(ev){
    if ($(this).hasClass('export_list_item_folded')) {
      $(this).css('height', '');
      $(this).removeClass('export_list_item_folded', 500);
      $(this).find('.exitem_switch img').attr('src', '/img/folding_down.png');
      $(this).find('.export_list_text_container').animate({top:0}, {duration: 500, complete:function(){ $(this).css('top','');}});
    } else {
      $(this).css('height', '');
      $(this).addClass('export_list_item_folded');
      var sliding = $(this).find('.export_list_text_container').css('top').replace('px','');
      $(this).removeClass('export_list_item_folded');
      $(this).addClass('export_list_item_folded', 500);
      $(this).find('.export_list_text_container').animate({top:sliding}, {duration: 500, complete:function(){ $(this).css('top','');}});
      $(this).find('.exitem_switch img').attr('src', '/img/folding_left.png');
    }
  });
  $("#exitem_sort_class, #exitem_sort_order").live('change', function(){ sort_dives($("#exitem_sort_class").val(), $("#exitem_sort_order").val());  });

  $("#wizard_bulk_apply_trip").live('click', request_bulk_trip);
  $("#wizard_bulk_apply_shop").live('click', request_bulk_shop);
  $("#wizard_bulk_apply_buddy").live('click', request_bulk_buddy);
  $("#wizard_bulk_apply_water").live('click', request_bulk_water);
  $("#wizard_bulk_apply_visibility").live('click', request_bulk_visibility);
  $("#wizard_bulk_apply_altitude").live('click', request_bulk_altitude);
  $("#wizard_bulk_apply_location").live('click', request_bulk_location);
  $("#wizard_bulk_apply_gear").live('click', request_bulk_gear);
  $("#wizard_bulk_apply_print").live('click', request_bulk_print);
  $("#wizard_bulk_numbering_div_magic").live('click', magic_bulk_numbering);
  $("#wizard_bulk_numbering_data input").live('change', update_following_dives_numbering);
  $("#wizard_bulk_apply_numbering").live('click', request_bulk_number);

  try {
    $('a.add_own_gear').live('click', own_new_gear);
    $('.data_gear').each(function(idx, elt) { $(elt).data('diveboard_gear_wizard', JSON.parse($('<div></div>').html($(elt).attr('data-diveboard_gear_wizard')).text()  ) )  });
  } catch(e){}

}

function wizard_initialize_galleria()
{
  if (wizard_galleria_initialized) return;
  wizard_galleria_initialized = true;

  $("#galleria-wizard").resize(function(){
    var dim = $(this).getHiddenDimensions(false);
    $("#galleria-wizard-bin").css('height', dim.height);
    //$("#galleria-wizard-bin").css('height', $(this).height());
  });

  $("#galleria-wizard").neat_gallery({
    width: 500,
    max_height: 100,
    coverIndex: G_dive_picture_cover,
    source: dive_pictures_data,
    onclick: ceebox_wizard_popup, /*function(idx, img, evt){ TODO open a regular lightbox },*/
    loading: function(){ $("#galleria-wizard-loading").show();  },
    loaded: function(){ $("#galleria-wizard-loading").hide();  },
    editable: true
  });

  $("#cee_wizard").die('click');

  $('#wizard-picture-toggle-list').click(function(){
    $('#wizard-picture-toggle-gallery').removeClass('toggle_button_active');
    $('#wizard-picture-toggle-list').addClass('toggle_button_active');
    create_edit_list();
    $("#galleria-wizard-container").hide();
    $("#wizard-picture-list").show();
  });
  $('#wizard-picture-toggle-gallery').click(function(){
    $('#wizard-picture-toggle-gallery').addClass('toggle_button_active');
    $('#wizard-picture-toggle-list').removeClass('toggle_button_active');
    $("#galleria-wizard-container").show();
    $("#wizard-picture-list").hide();
  });

  $("#galleria-wizard-bin").droppable({
    drop: function(ev, ui) {
      $(ui.draggable).draggable( "option", "revert", false );
      $("#galleria-wizard").neat_gallery("remove_obj")($(ui.draggable));
    },
    over: function(event, ui) {
      $(this).addClass('dragging');
    },
    out: function(event, ui) {
      $(this).removeClass('dragging');
    }
  });
}



/////////////////////////////
//
// FUNCTIONS TO SET DATA
//
/////////////////////////////

function sortstops(a,b){
  //sorts by depth in reverse
  return parseInt(b[0])-parseInt(a[0]);
}

function  divecomplete(){
  /*
  if ($("#wizard-duration-mins").val() != "0" && $("#wizard-duration-mins").val() != "" && $("#wizard-max-depth").val() != "" &&$("#wizard-max-depth").val() != "0.0" && $("#©").val()!= "1"){
    if (G_user_fb_perms_post_to_wall && !G_dive_posted_to_fb_wall && G_user_setting_auto_share) {
      $("#fb_post_button").attr("checked", true);
    } else {
      $("#fb_post_button").attr("checked", false);
    }
    $("#fb_post").show();
  }
  else {
    $("#fb_post_button").attr("checked", false);
  }*/
}


function wizard_save_close(e){
  //Cancel the link behavior
  if (e != null){
    e.preventDefault();
  }

  window.onbeforeunload = null;

  if( wizard_spot_datacheck()==false ){
    show_map_tab();
    alert(I18n.t(["js","wizard","ERROR: Cannot Save. Please correct the fields highlighted in red"]));
    return;
  }

  if ((wizard_compare_spot_data() || wizard_spot_datacheck() == true ) && wizard_dive_datacheck()){

    //first, save the spot if it changed
    //if returns false, then the user needs to answer some questions
    //about what to do with the spot, so let's wait for his answer
    if (!wizard_check_create_spot(wizard_save_close, false))
      return;

    //Empty the examples
    $('.example').val('');

    //show the progressing cursor
    diveboard.mask_file(true, {"z-index": 90000});

    var url;
    if (G_dive_id == null || G_diveuser_vanity_url == "")
      url = "/"+G_user_vanity_url+"/create.json";
    else
      url = "/"+G_owner_vanity_url+"/"+G_dive_id+"/update.json";

    var stops = new Array();
    var total_stop_time = 0;

    $("#profile_table .stop_def").each(function(i,e){
      var stop = $(e);
      var stop_depth = stop.find(".stop_depth").val();
      var stop_depth_unit = stop.find(".stop_depth_unit").val();
      var stop_time = stop.find(".stop_time").val();
      if(stop_depth != "" && stop_time != "") {
        stops.push([stop_depth, stop_time, stop_depth_unit ]);
        total_stop_time += parseInt(stop_time);
      }

    })

    //Sort the stops from  deep to shallow
    stops = stops.sort(sortstops); // sort by depth in reverse

    var all_divetypes = $.map($('.wizard_divetype:checked'), function(elt, idx){ return elt.value });
    if ($('#wizard_divetype_other').val() != '')
      all_divetypes.push( $('#wizard_divetype_other').val())

    var picture_list = $("#galleria-wizard").neat_gallery("list")();
    var favorite_picture=null;
    if (picture_list.length > 0)
      favorite_picture = picture_list[0].image;

    $.each(picture_list, function(idx, img){
      if ($('#wizard-picture-list-edit-'+img.id).length > 0) {
        //TODO
        picture_list[idx]['tags'] = JSON.parse($('#wizard-picture-list-edit-'+img.id+' p.selected_species_list').attr("data"));
        picture_list[idx]['notes'] = $('#wizard-picture-list-edit-'+img.id+' .picture_notes').val();
      }
      else {
        picture_list[idx]['tags'] = G_wizard_picture_tags['wizard_video_'+img.id];
        picture_list[idx]['notes'] = G_wizard_picture_notes['wizard_video_'+img.id];
      }
    });

    var diveshop = null;
    if ($("#wz_shop_found_id").val() == '' && $('#diveshop-name').attr('readonly')) {
      diveshop = new Object();
      diveshop['name'] = $("#diveshop-name").val();
      diveshop['country'] = $("#diveshop-country").val();
      diveshop['town'] = $("#diveshop-town").val();
      diveshop['url'] = $("#diveshop-url").val();
      diveshop['request_signature'] = $("#signing_shop_request").prop("checked");
      if (diveshop['name'] =="") diveshop['name'] = diveshop['url'];
      if (diveshop['name'] =="") diveshop = null;
    }else if ($("#signing_shop_request").prop("checked")){
       diveshop = new Object();
       diveshop['request_signature'] = $("#signing_shop_request").prop("checked");
    }


    var gear = [];
    $('.gear_wizard_table .data_gear').each(function(i, elt){
      var data = $(elt).data('diveboard_gear_wizard');
      data.featured = ($(elt).find('.featured:checked').length > 0);
      if ($(elt).find('.absent:checked').length == 0)
        gear.push(data);
    });

    var dan_data = null;
    if (!$("#dan_allow_update").is(':visible')) {
      dan_data = JSON.stringify(dan_form_to_hash($('.dan_form')));
    }

    var weights_value = $("#wizard-weights").val()==""?"":parseFloat($("#wizard-weights").val());
    var weights_unit = $("#wizard-weights").val()==""?"":$("#wizard-weights-unit").val();

    var fish_list ="";
    $.each(G_dive_fishes, function(index, value){
      if(index>0)
        fish_list += ",";
      fish_list += value.id;
    });
    //G_dive_fishes.map(function(e){return e.id;}).toString();
    var altitude = $("#altitude").val()==""?"":unit_distance_n(parseFloat($("#altitude").val()), true);

    var list_stars = {};
    // var stars = $("input[name=star_overall]:checked").val();
    // if (stars)
    //    list_stars.overall = stars;
    // stars = $("input[name=star_difficulty]:checked").val();
    // if (stars)
    //   list_stars.difficulty = stars;
    // stars = $("input[name=star_marine]:checked").val();
    $("#wizard_dive_review .hover-star:checked").each(function(i, e)
    {
      var star = $(e);
      list_stars[star.attr("name")] = star.val();
    });


    var has_bottom_temp = isFloat($("#wizard-bottom-temperature").val())?true:"";
    var has_surface_temp = isFloat($("#wizard-surface-temperature").val())?true:"";

    data_to_send = {
      user_id: G_owner_api.id,
      number: Number($("#wizard-dive-number").val()),
      spot_id: $("#spot-id").val(),
      update_profile: $("#profile-updated").val(),
      fileid: $("#profile-fileid").val(),
      diveid: $("#profile-diveid").val(),
      date:  $("#wizard-date").val(),
      time_in_hrs: $("#wizard-time-in-hrs").val(),
      time_in_mins: $("#wizard-time-in-mins").val(),
      duration: $("#wizard-duration-mins").val(),
      surface_interval: $("#wizard-surface-interval").val(),
      max_depth_value: parseFloat($("#wizard-max-depth").val()),
      max_depth_unit: $("#wizard-max-depth-unit").val(),

      surface_temp_value: has_surface_temp && parseFloat($("#wizard-surface-temperature").val()),
      surface_temp_unit: has_surface_temp && $("#wizard-surface-temperature-unit").val(),

      bottom_temp_value: has_bottom_temp && parseFloat($("#wizard-bottom-temperature").val()),
      bottom_temp_unit: has_bottom_temp && $("#wizard-bottom-temperature-unit").val(),

      weights_value: weights_value,
      weights_unit: weights_unit,

      fish_list: fish_list,
      notes: $("#wizard-dive-notes").val(),
      pictures: JSON.stringify(picture_list),
      favorite_picture: favorite_picture,
      divetype: all_divetypes,
      divebuddy: JSON.stringify(get_buddy_object()),
      safetystops: JSON.stringify(stops),
      tanks: JSON.stringify(extract_tank_data()),
      gear: JSON.stringify(gear),
      visibility: $("#wizard-visibility").val(),
      current: $("#wizard-current").val(),
      trip_name: $("#wizard-trip").val(),
      'authenticity_token': auth_token,
      posttowall: false,
      altitude: altitude,
      water: $("#water").val(),
      dan_data: dan_data,
      send_to_dan: !!$("#send_to_dan").attr('checked'),  //Must be a boolean so double not
      fbtoken: G_user_fbtoken,
      list_stars: JSON.stringify(list_stars)
    };

    if ($("#guide").val()) data_to_send['guide'] = $("#guide").val();
    if ($("#wz_shop_found_id").val()) data_to_send['shop_id'] = $("#wz_shop_found_id").val();
    else data_to_send['shop_id'] = '';
    if (diveshop) {
      data_to_send['diveshop'] = JSON.stringify(diveshop);
    } else data_to_send['diveshop'] = {}
    $.ajax({
      url: url,
      dataType: 'json',
      data: data_to_send,
      type: "PUT",
      success: function(data){
        if (data.success && (data.messages == null||data.messages.length==0)){
          dive_updated = true; //used to know why we're closing wizard
          //there is no real point in not reloading everything....
          window.location.replace("/" + G_owner_vanity_url+"/"+data.dive_id+"?updated=true");
        } else if (data.success) {
          dive_updated = true; //used to know why we're closing wizard
          diveboard.alert(I18n.t(["js","wizard","The dive could not be completely updated :"])+" <br/>&nbsp;&nbsp;&nbsp;- "+data.messages.join(""), data, function(){
            window.location.replace("/" + G_owner_vanity_url+"/"+data.dive_id+"?updated=true");
          });

        } else {
          //detail the alert
          dive_updated = false; //used to know why we're closing wizard
          diveboard.alert(I18n.t(["js","wizard","A technical error occured."]), data, function(){
            $("#file_mask").css("z-index", 9000);
            close_wizard();
          });
        }
      },
      error: function(data) {
        dive_updated = false; //used to know why we're closing wizard
        diveboard.alert(I18n.t(["js","wizard","A technical error occured while saving the dive. Please make sure your internet connection is up and try again."]), null, function() {
          $("#file_mask").css("z-index", 9000);
          close_wizard();
          //location.replace("/" + G_owner_vanity_url);
        });
      }
    });
  }
}

function bulk_request_signature(){
 list_of_dives = [];

  $("#wizard_export_list input:checked").each(function(index, value) {
    list_of_dives.push(value.name);
  });

  if (list_of_dives.length == 0){
    alert(I18n.t(["js","wizard","You must select at least one dive to update privacy"]));
    return;
  }


  var actions = {};
  actions[I18n.t(["js","wizard","Cancel"])] = function() { $(this).dialog("close") };
  actions[I18n.t(["js","wizard","Request Signature"])] = function(){
      $( this ).dialog( "close" );
        var requests_obj = [];

      $('#wizard_export_list input:checked').each(function(idx, elt){
        var params_obj = {
          id: parseInt(elt.name),
          dive: {
            request_shop_signature: true
          }
        };

        requests_obj.push({
          call: '/dive/update',
          method: 'post',
          params: params_obj
        });
      });

      request_bulk_ajax(requests_obj);

    };
  diveboard.propose(
    I18n.t(["js","wizard","Request Logbook Signature"]),
    I18n.t(["js","wizard","You have requested signature for %{count} dives. Signature requests already sent won't be renewed. Dives without a dive shop won't be submitted."], {count: list_of_dives.length}),
    actions
  );
}

function delete_dive(){
  //show confirmation popup
  $( "#dialog-confirm" ).dialog({
    resizable: false,
    modal: true,
    zIndex: 99999,
    width: 500,
    buttons: {
      "Delete dive": function() {
        window.onbeforeunload = null;
        var url = "/"+G_owner_vanity_url+"/"+G_dive_id+"/delete.json";
        $( this ).dialog( "close" );
        diveboard.mask_file(true, {"z-index": 90000});
        $.ajax({
          url: url,
          dataType: 'json',
          data: ({ 'authenticity_token': auth_token }),
          type: "PUT",
          success: function(data){
            if (data.success)
              location.replace("/"+G_owner_vanity_url+"/");
            else
              diveboard.alert(I18n.t(["js","wizard","A technical error occured. Most probably, your dive hasn't been deleted."]), data, function() {
                location.replace("/"+G_owner_vanity_url+"/");
              });
          },
          error: function(data) {
            diveboard.alert(I18n.t(["js","wizard","A technical error occured. Most probably, your dive hasn't been deleted."]), null, function() {
              location.replace("/"+G_owner_vanity_url+"/");
            });
          }
        });
      },
      'Cancel': function() {
        $( this ).dialog( "close" );
      }
    }
  });
$(".ui-dialog").position({
   my: "center",
   at: "center",
   of:".ui-widget-overlay"
});
}


/////////////////////
//
// SPOTS
//
/////////////////////

function select_spot(spotid){
  if (!wizard_maps_loaded && spotid != 1)
    wizard_gmaps_init(false);


  wizard_spot_make_changeable(false);
  
  if (spotid == 1) {
    $('#wizard_search_spot').show();
    $("#wzgmapcontainer").hide();
    $("#set_spot_details").hide();
    $("#wizard_spot_modspot, #wizard_spot_remove").hide();
  }
  else {
    $('#wizard_search_spot').hide();
    $("#wzgmapcontainer").show();
    $("#set_spot_details").show();
    $("#wizard_spot_modspot, #wizard_spot_remove").css("display", "inline-block");
  }
  $("#wizard_spot_creaspot").show();
  $("#wizard_spot_confirm, #wizard_spot_cancel, #wizard_spot_search, #wizard_simmilar_spots_label, #wizard_simmilar_spots").hide();
  if (G_dive_spot_id == 1)
    $("#wizard_spot_reset").hide();
  else
    $("#wizard_spot_reset").css("display", "inline-block");



  //Check if it has already been requested
  if (G_wizard_spot_data[spotid]) {
    wizard_show_spot_data(spotid);
    return;
  }

  //If we don't know anything about that spot, get the info from the server
  $.ajax({
    url:"/api/spotinfo.json",
    data:({'authenticity_token': auth_token, spotid:spotid}),
    type:"POST",
    dataType:"json",
    success:function(data){ //Insert Data into the INPUT VALUE DOM
      if (data.success) {
        G_wizard_spot_data[spotid] = data["spot"];
        wizard_show_spot_data(spotid);
      } else {
        diveboard.alert(I18n.t(["js","wizard","Something went wrong while getting the detailed information about the dive spot. You may want to try again."]), data);
      }
    },
    error:function(data) {
      diveboard.alert(I18n.t(["js","wizard","Something went wrong while getting the detailed information about the dive spot. You may want to try again."]));
    }
  });
}

function wizard_spot_make_changeable(readwrite){
  if (readwrite) {
    $('#set_spot_details').removeClass('spot_table_readonly').show();
    $('#set_spot_details input').attr('readonly', false);
    $('#spot-location-1, #spot-location-2, #spot-location-3').attr('readonly', true);
    $('#set_spot_details input[type="checkbox"]').attr('disabled', false);
    $("#wizard_zoom_set").show();
    $("#wzgmapcontainer").show();
    $("#xp_p1_search").val("");
    wizard_gmaps_init(true);
  }
  else {
    $('#set_spot_details').addClass('spot_table_readonly').show();
    $('#set_spot_details input').attr('readonly', true);
    $('#set_spot_details input[type="checkbox"]').attr('disabled', true);
    $("#wizard_zoom_set").hide();
    $("#wzgmapcontainer").show();
    wizard_gmaps_init(false);
    $("#wizardgmaps_placepin").hide();
    $("#wizardgmaps_removepin").hide();
  }
}


function wizard_show_spot_data(spot_id){
  //Clear forms
  $("#set_spot_details input").removeClass("wizard_input_error")
  $("#spotsearch").val("");

  //Set the values of the form
  $("#spot-name").val(G_wizard_spot_data[spot_id]["name"] || "");
  $("#spot-location-1").val(G_wizard_spot_data[spot_id]["location1"] || "");
  $("#spot-location-2").val(G_wizard_spot_data[spot_id]["location2"] || "");
  $("#spot-location-3").val(G_wizard_spot_data[spot_id]["location3"] || "");
  $("#spot-lat").val(G_wizard_spot_data[spot_id]["lat"] || 0.0);
  $("#spot-long").val(G_wizard_spot_data[spot_id]["long"] || 0.0);
  $("#spot-zoom").val(G_wizard_spot_data[spot_id]["zoom"] || 1);

  $("#spot-country").val(country_name_from_code(G_wizard_spot_data[spot_id]["country_code"]));
  $("#wizard-spot-flag").attr("src","/img/flags/"+G_wizard_spot_data[spot_id]["country_code"].toLowerCase()+".gif");
  $("#spot-country").attr("shortname", G_wizard_spot_data[spot_id]["country_code"].toLowerCase());
  
  //Reset javascript variables
  wizard_marker_moved = (spot_id!=1);
  wizard_no_spot_on_map = (spot_id==1);

  //Finalize the display of the form
  if (spot_id != 1)
  {
    wizard_gmaps_init(false);
  }
  $("#spot-id").val(spot_id);

  //update the Fish list for the local spot
  update_species_list(Number($("#spot-lat").val()), Number($("#spot-long").val()));

  divecomplete();
}

function wizard_compare_spot_data(){
  var spotid = $("#spot-id").val();
  return (
    $("#spot-location-1").val() == (  G_wizard_spot_data[spotid]["location1"] || "") &&
    $("#spot-location-2").val() == (  G_wizard_spot_data[spotid]["location2"] || "") &&
    $("#spot-location-3").val() == (  G_wizard_spot_data[spotid]["location3"] || "") &&
    $("#spot-name").val() == (G_wizard_spot_data[spotid]["name"]  || "") &&
    $("#spot-country").attr("shortname") == G_wizard_spot_data[spotid]["country_code"].toLowerCase()  &&
    $("#spot-lat").val() == (G_wizard_spot_data[spotid]["lat"]  || 0) &&
    $("#spot-long").val() == (G_wizard_spot_data[spotid]["long"]  || 0)
  );
}

function reset_spot_details(){
  wizard_correct_dive = false;
  select_spot(G_dive_spot_id);
}

function wizard_store_current_spot() {
  var spotid = $("#spot-id").val();
  if (G_wizard_spot_data[spotid] == null) {
    G_wizard_spot_data[spotid] = {};
    G_wizard_spot_data[spotid]["location1"] = $("#spot-location-1").val() ;
    G_wizard_spot_data[spotid]["location2"] = $("#spot-location-2").val() ;
    G_wizard_spot_data[spotid]["location3"] = $("#spot-location-3").val() ;
    G_wizard_spot_data[spotid]["name"]  = $("#spot-name").val() ;
    G_wizard_spot_data[spotid]["country_code"] = $("#spot-country").attr("shortname");
    G_wizard_spot_data[spotid]["lat"]  = $("#spot-lat").val() ;
    G_wizard_spot_data[spotid]["long"]  = $("#spot-long").val() ;
    G_wizard_spot_data[spotid]["zoom"]  = $("#spot-zoom").val() ;
  }
}

function wizard_check_create_spot(resume, async){
coco = resume;
  if (wizard_compare_spot_data())
    return(true);

  if(!wizard_spot_datacheck()){
    alert(I18n.t(["js","wizard","Some spot data were input incorrectly, please correct them before proceeding"]));
    return;
  }

  if ($("#spot-id").val() == 1) {
    //TODO: create spot anyway
    wizard_update_or_create_spot(null, async);
    return(true);
  }
  else if ($("#spot-id").val() != 1) {

    var spotid = $("#spot-id").val();
    $("#country-old").html(G_wizard_spot_data[spotid]["country_code"].toUpperCase());
    $("#location-old-1").html(G_wizard_spot_data[spotid]["location1"]);
    $("#location-old-2").html(G_wizard_spot_data[spotid]["location2"]);
    $("#location-old-3").html(G_wizard_spot_data[spotid]["location3"]);
    $("#name-old").html(G_wizard_spot_data[spotid]["name"]);
    $("#lat-old").html(G_wizard_spot_data[spotid]["lat"]);
    $("#long-old").html(G_wizard_spot_data[spotid]["long"]);

    $("#country-new").html($("#spot-country").attr("shortname").toUpperCase());
    $("#location-new-1").html($("#spot-location-1").val());
    $("#location-new-2").html($("#spot-location-2").val());
    $("#location-new-3").html($("#spot-location-3").val());
    $("#name-new").html($("#spot-name").val());
    $("#lat-new").html(Math.round(10000*$("#spot-lat").val())/10000);
    $("#long-new").html(Math.round(10000*$("#spot-long").val())/10000);

    $("#spotchanged-table").removeClass("spotchanged-datachanged");

    if ($("#spot-location-1").val() != (G_wizard_spot_data[spotid]["location1"] || "")) $("#location-new-1").addClass("spotchanged-datachanged");
    if ($("#spot-location-2").val() != (G_wizard_spot_data[spotid]["location2"] || "")) $("#location-new-2").addClass("spotchanged-datachanged");
    if ($("#spot-location-3").val() != (G_wizard_spot_data[spotid]["location3"] || "")) $("#location-new-3").addClass("spotchanged-datachanged");
    if ($("#spot-name").val() != (G_wizard_spot_data[spotid]["name"]  || "")) $("#name-new").addClass("spotchanged-datachanged");
    if ($("#spot-country").attr("shortname") != G_wizard_spot_data[spotid]["country_code"].toLowerCase() ) $("#country-new").addClass("spotchanged-datachanged");
    if ($("#spot-lat").val() != (G_wizard_spot_data[spotid]["lat"]  || "")) $("#lat-new").addClass("spotchanged-datachanged");
    if ($("#spot-long").val() != (G_wizard_spot_data[spotid]["long"]  || "")) $("#long-new").addClass("spotchanged-datachanged");

    $( "#dialog-spotchanged" ).dialog({
      resizable: false,
      modal: true,
      width: 550,
      zIndex: 99999,
      buttons: {
        "It is a different dive site": function() {
          $( "#dialog-spotchanged" ).dialog("close");
          diveboard.mask_file(true);
          setTimeout(function(){
            wizard_update_or_create_spot(null, async);
            diveboard.unmask_file();
            if (resume) resume();
            }, 100);

        },
        "It's the same site, please update": function() {
          $( "#dialog-spotchanged" ).dialog("close");
          diveboard.mask_file(true);
          setTimeout(function(){
            wizard_update_or_create_spot($("#spot-id").val(), async);
            diveboard.unmask_file();
            if (resume) resume();
          }, 100);
        },
        "Cancel": function() {
          $( "#dialog-spotchanged" ).dialog("close");
        }
      }
    });
    $(".ui-dialog").position({
   my: "center",
   at: "center",
   of:".ui-widget-overlay"
  });
    return(false);
  }
  return(true);
}


function wizard_update_or_create_spot(spot_id, as_var){
  //as_var = true or false - ensures the new spot is NOT create asynchronously befor we save the whole wizard
  divecomplete();

  $.ajax({
    url: "/api/spotupdate",
    async: as_var,
    data: ({
      'authenticity_token': auth_token,
      //add difference between create and update
      spotid: (spot_id||""),
      diveid: $("#dive-id").val(),
      location1: $("#spot-location-1").val(),
      location2: $("#spot-location-2").val(),
      location3: $("#spot-location-3").val(),
      country: $("#spot-country").attr("shortname"),
      name: $("#spot-name").val(),
      lat: $("#spot-lat").val(),
      lng: $("#spot-long").val(),
      zoom: $("#spot-zoom").val(),
      precise: false
    }),
    type: "POST",
    dataType: "json",
    success: function(data) {
      if (data["success"]){
        G_wizard_spot_data[data["spot"]["id"]] = data["spot"];
        $("#spot-id").val(data["spot"]["id"]);
        select_spot(data["spot"]["id"]);
      }else{
        diveboard.alert(I18n.t(["js","wizard","Due to a technical error, your changes on the spot could not be saved."]), data);
      }
    },
    error: function(data){
      diveboard.alert(I18n.t(["js","wizard","Due to a technical error, your changes on the spot could not be saved."]));
    }
  });
}



///////////////////////////
//
// PICTURES
//
///////////////////////////

function wizard_clean_galleria(){

  $("#galleria-wizard").neat_gallery("clean")();

  if (G_dive_featured_picture == "") {
    $("#favorite-picture-id").val("");
    $("#favoritepic").empty();
    $("#favoritepic").html(I18n.t(["js","wizard","Favorite pic #1"])+" | ")
  } else {
    $("#favorite-picture-id").val(G_dive_featured_picture);
    init_favorite_picture_id();
  }
}


function wizard_add_picture(ev){
  if (ev) ev.preventDefault();
  var picturl = $("#wizard_pict_url").val();
  picturl = picturl.replace(/^[^a-zA-Z0-9#%/?=&:;@$_.+!*'(),-]*/,'');
  picturl = picturl.replace(/[^a-zA-Z0-9#%/?=&:;@$_.+!*'(),-]*$/,'');
  $("#wizard_pict_url").val("");
  var baseurl = picturl;//.split(/\?/)[0];
  if (baseurl.match(/^http.*\.(?:jpg|gif|png)/i) != null){
    //picturl is an actual url directly pointing to a picture
    //http://flickr.com/photo.gne?id=2177060015
    var pict_link=baseurl;
    if (baseurl.match(/static\.flickr\.com\//i) != null && baseurl.match(/\/([0-9]+)_.*\.(?:jpg|gif|png)/i) != null){
      // that's a flickr image linked directly to
      id = baseurl.match(/\/([0-9]+)_.*\.(?:jpg|gif|png)/)[1];
      pict_link = "http://flickr.com/photo.gne?id="+id;
    }
    var newimage = { image: baseurl, link: pict_link};
    add_newimage(newimage);
  }
  else if (baseurl.match(/flickr\.com/i) != null && baseurl.match(/sets\/([0-9]+)/) != null ){
    //this is a flickr url for a set
    var photoset_id= baseurl.match(/\/([0-9]+)\//)[1];
    $.ajax({
      url: "https://api.flickr.com/services/rest/",
      dataType: 'jsonp',
      data: ({
        method: "flickr.photosets.getPhotos",
        format: "json",
        extras: "url_sq, url_t, url_s, url_m, url_o",
        api_key: G_flickr_key,
        photoset_id: photoset_id,
        jsoncallback : "add_photoset_from_flickr"
        }),
      error: function(data) { diveboard.alert(I18n.t(["js","wizard","A technical error happened while connecting to Flicker."])); },
      jsonp: false,
      jsonpCallback: "add_image_from_flickr",
      type: "get"
    });
  }
  else if (baseurl.match(/flickr\.com/i) != null && baseurl.match(/photos\/[^\/]*\/([0-9]+)/) != null && baseurl.match(/\/sets\//i) == null){
    //this is a flickr url
    picture_id = baseurl.match(/photos\/[^\/]*\/([0-9]+)/)[1];
  //https://api.flickr.com/services/rest/?method=flickr.photos.getInfo&api_key=01b0b6477ea1c4b7caf08dc1b3f8929d&photo_id=384642622
    $.ajax({
      url: "https://api.flickr.com/services/rest/",
      dataType: 'jsonp',
      data: ({
        method: "flickr.photos.getinfo",
        format: "json",
        api_key: G_flickr_key,
        photo_id: picture_id,
        jsoncallback : "add_image_from_flickr"
        }),
      error: function(data) { diveboard.alert(I18n.t(["js","wizard","A technical error happened while connecting to Flicker."])); },
      jsonp: false,
      jsonpCallback: "add_image_from_flickr",
      type: "get"
    });
  }else if (baseurl.match(/^http:\/\/flic.kr\/p\/(.*)$/i) != null){
    //flickr tiny url
    picture_id = base_58_decode(baseurl.match(/^http:\/\/flic.kr\/p\/(.*)$/i)[1]);
    $.ajax({
      url: "https://api.flickr.com/services/rest/",
      dataType: 'jsonp',
      data: ({
        method: "flickr.photos.getInfo",
        format: "json",
        api_key: G_flickr_key,
        photo_id: picture_id,
        jsoncallback : "add_image_from_flickr"
        }),
      error: function(data) { diveboard.alert(I18n.t(["js","wizard","A technical error happened while connecting to Flicker."])); },
      jsonp: false,
      jsonpCallback: "add_image_from_flickr",
      type: "GET"
    });
  }else if(baseurl.match(/www\.facebook\.com/)!= null && baseurl.match(/fbid\=([0-9]+)/i) != null){
    //facebook url
    picture_id = baseurl.match(/fbid\=([0-9]*)/i)[1];

    if(G_user_fb_perms_add_fb_pict != true){
      FB.login(function(response) {
        fb_response = response ;
        if (response.perms != undefined && response.perms.match(/user\_photos/)!=null && response.perms.match(/user\_videos/)!=null) {
        G_user_fbtoken = response.authResponse.accessToken;
        check_fb_pict_url(picture_id);
        } else {
          // user cancelled login
        return;
        }
      }, {scope:'user_photos,user_videos,email'});
    }else{
      check_fb_pict_url(picture_id);
    }
  }else if(baseurl.match(/www\.facebook\.com/)!= null && baseurl.match(/set\=[^.]*\.([0-9]+)\./i) != null){
    //it's an album upload request
    var album_id = baseurl.match(/set\=[^.]*\.([0-9]*)/i)[1];

    check_fb_album_url(album_id);


  }else if(baseurl.match(/picasaweb\.google\.com\/([0-9a-zA-Z_.-]*)\/.*authkey=([^&]*).*#([0-9]*)/i)!= null ){
    //Picasa with authorisation key
    matched = baseurl.match(/picasaweb\.google\.com\/([0-9a-zA-Z_.-]*)\/.*authkey=([^&]*).*#([0-9]*)/i);
    var auth_key = matched[2];
    var picture_id = matched[3];
    var user_id = matched[1];
    $.ajax({
      url: "https://picasaweb.google.com/data/feed/api/user/"+user_id+"/photoid/"+picture_id,
      dataType: 'jsonp',
      jsonpCallback: "add_image_from_picasa",
      data: {
        alt: "json",
        authkey: auth_key
        },
      error: function(data) { diveboard.alert(I18n.t(["js","wizard","A technical error happened while connecting to Picasa."])); },
      type: "GET"
    });

  }else if( baseurl.match(/picasaweb.google.com\/lh\/photo\/([a-zA-Z0-9\-\_]+)\?/) || baseurl.match(/picasaweb.google.com\/lh\/photo\/([a-zA-Z0-9\-\_]+)$/)){
    //alert("sorry, the picasa \"share\" link format is not supported at the moment - please paste the url from the navigation bar of your browser instead");
    $.ajax({
      url: "/api/pictures/picasa_share",
      dataType: 'json',
      data: {
        link: baseurl
      },
      type: "GET",
      success: function(data) {
        if (data.success){
          var photoURL = data.image;
          var link = data.url;
          add_newimage({image: photoURL, link: link});
        }else{
          diveboard.alert(I18n.t(["js","wizard","A technical error happened while trying to connect to Picasa."]), data);
        }
      },
      error: function(data) { diveboard.alert(I18n.t(["js","wizard","A technical error happened while trying to connect to Picasa."])); }
    });



  }else if(baseurl.match(/picasaweb\.google\.com\/[0-9a-zA-Z_.-]*\/.*#[0-9]*/i)!= null){
    //picasa url without authorisation key
    matched = baseurl.match(/picasaweb\.google\.com\/([0-9a-zA-Z_.-]*)\/.*#([0-9]*)/i)
    var picture_id = matched[2];
    var user_id = matched[1];
    $.ajax({
      url: "https://picasaweb.google.com/data/feed/api/user/"+user_id+"/photoid/"+picture_id,
      dataType: 'jsonp',
      jsonpCallback: "add_image_from_picasa",
      data: {
        alt: "json"
        },
      error: function(data) { diveboard.alert(I18n.t(["js","wizard","A technical error happened while trying to connect to Picasa."])); },
      type: "GET"
    });

  }else if(baseurl.match(/plus\.google\.com\/photos\/[0-9]+\/albums\/[0-9]+\/[0-9]+/i)!= null){
    //https://plus.google.com/photos/103180330852418292309/albums/5455927946463655681/5455929882856931394
    //g+ url without auth key
    matched = baseurl.match(/plus\.google\.com\/photos\/([0-9]+)\/albums\/[0-9]+\/([0-9]+)/i)
    var picture_id = matched[2];
    var user_id = matched[1];
    $.ajax({
      url: "https://picasaweb.google.com/data/feed/api/user/"+user_id+"/photoid/"+picture_id,
      dataType: 'jsonp',
      jsonpCallback: "add_image_from_picasa",
      data: {
        alt: "json"
        },
      error: function(data) { diveboard.alert(I18n.t(["js","wizard","A technical error happened while trying to connect to Picasa."])); },
      type: "GET"
    });

  }else if(baseurl.match(/picasaweb\.google\.com\/[0-9a-zA-Z_.-]*\/.*\?.*authkey=[a-zA-Z0-9]*/i)!= null ){
    //picasa album with authorisation cannot be supported without Oauth protocol support.....
    alert(I18n.t(["js","wizard","Sorry, due to API restriction, we cannot import pictures from albums private or with limited access."]));

  }else if(baseurl.match(/picasaweb\.google\.com\/[0-9a-zA-Z_.-]*\//i)!= null ){
    //picasa album url without authorisation key
    var user_id = baseurl.match(/picasaweb\.google\.com\/([0-9a-zA-Z_.-]*)\//i)[1];
    G_asked_album_url = baseurl.split("?")[0];
    if (user_id.match(/[0-9]+/)){
      $.ajax({
        url: "https://picasaweb.google.com/data/feed/api/user/"+user_id,
        dataType: 'jsonp',
        jsonpCallback: "find_album_from_picasa",
        data: {
          alt: "json"
        },
        error: function(data) { diveboard.alert(I18n.t(["js","wizard","A technical error happened while trying to connect to Picasa."])); },
        type: "GET"
      });
    }else{

      G_asked_album_url = G_asked_album_url.replace(user_id,"UID");
      //user id is not the uid but an alias we need to crack first
      $.ajax({
        url: "https://picasaweb.google.com/data/feed/api/user/"+user_id,
        dataType: 'jsonp',
        jsonpCallback: "picasa_user",
        data: {
          alt: "json"
        },
        error: function(data) { diveboard.alert(I18n.t(["js","wizard","A technical error happened while trying to connect to Picasa."])); },
        type: "GET"
      });
    }
  }else if(baseurl.match(/plus\.google\.com\/photos\/[0-9]+\/albums\/[0-9]+/i)!= null ){
    //g+ album url without authorisation key
    var matchdata = baseurl.match(/plus\.google\.com\/photos\/([0-9]+)\/albums\/([0-9]+)/i);
    var user_id = matchdata[1];
    G_asked_album_url = matchdata[2];
    if (user_id.match(/[0-9]+/)){
      $.ajax({
        url: "https://picasaweb.google.com/data/feed/api/user/"+user_id,
        dataType: 'jsonp',
        jsonpCallback: "find_album_from_picasa",
        data: {
          alt: "json"
        },
        error: function(data) { diveboard.alert(I18n.t(["js","wizard","A technical error happened while trying to connect to Picasa."])); },
        type: "GET"
      });
    }else{

      G_asked_album_url = G_asked_album_url.replace(user_id,"UID");
      //user id is not the uid but an alias we need to crack first
      $.ajax({
        url: "https://picasaweb.google.com/data/feed/api/user/"+user_id,
        dataType: 'jsonp',
        jsonpCallback: "picasa_user",
        data: {
          alt: "json"
        },
        error: function(data) { diveboard.alert(I18n.t(["js","wizard","A technical error happened while trying to connect to Picasa."])); },
        type: "GET"
      });
    }
  }else if(baseurl.match(/dailymotion\.com/i)!= null ||baseurl.match(/youtube\.com/i)!= null ||baseurl.match(/youtu\.be/i)!= null || baseurl.match(/vimeo\.com/i)!= null|| baseurl.match(/facebook\.com\/video/i)!= null|| baseurl.match(/facebook\.com\/.*\?v=[0-9]+/i)!= null || baseurl.match(/facebook\.com\/v\/[0-9]+/i)!= null){
  // this is a video
  $.ajax({
    url: "/api/get_videothumb.json",
    dataType: 'json',
    data: {
      user_id: G_owner_id,
      url: baseurl
    },
    type: 'GET',
    error: function(data) {
      diveboard.alert(I18n.t(["js","wizard","A technical error happened while trying to connect to video provider."]));
    },
    success: function(data){
      if(data.success){
        url = data.thumb;
        add_newimage({image: url, link: data.video});
      }else if(data.error == "Invalid url") {
        diveboard.notify(I18n.t(["js","wizard","Adding pictures and videos"]), I18n.t(["js","wizard","The URL you provided does not seem valid. Please check and retry."]));
      }else{
        diveboard.alert(I18n.t(["js","wizard","A technical error happened while trying to connect to video provider."]));
      }
    }
  });

  }else{
    alert("Unrecognized picture url, sorry!");
    $("#wizard_pict_url").val("");
  }
}





var G_picture_uploader = null;
function setup_upload_pictures(){
  image_resizer = new diveboard.resizer();
  if (diveboard.resizer.support()){
    $(".diveboard-resizer-selector").show();
  }

  qq.extend(qq.UploadHandlerXhr.prototype, {
    add: function(file){
      return this._files.push(file) - 1;
    },
    getSize: function(id){
        var file = this._files[id];
        if (file instanceof File)
          return file.fileSize != null ? file.fileSize : file.size;
        else
          return file.length;
    }
  });

  qq.CustomizedFileUploader = function(o) {
    // call parent constructor
    qq.FileUploader.apply(this, arguments);
    this._options.classes['dropActive'] = 'wizard-picture-add-active'
    this._classes['dropActive'] = 'wizard-picture-add-active'
  }
  qq.extend(qq.CustomizedFileUploader.prototype, qq.FileUploader.prototype);
  qq.extend(qq.CustomizedFileUploader.prototype, {
    _uploadFileList: function(files){
      var uploader = this;
      var hasPicture = false;
      var forecasted_size = 0;
      var notimage_size = 0;

      $.each(files, function(i,e) {
        forecasted_size += e.fileSize;
        if (e.type.match(/image/)) hasPicture = true;
        else notimage_size += e.fileSize;
      });

      var quota_issue = check_storage_quota(notimage_size);
      if (quota_issue == 'per_user') {
        alert(I18n.t(["js","wizard","You have reached your quota of %{count}Gb. These files cannot be uploaded. Please remove image or video content from this dive or another."], {count: Math.round(G_private_user['quota_limit']/(1024*1024*1024)) }));
        return;
      };
      if (quota_issue == 'per_month') {
        alert(I18n.t(["js","wizard","You have reached the default limit of %{count}Mb of upload per month. These files cannot be uploaded. Please downsize your files, or ask for a bigger storage."], {count: Math.round(G_private_user['quota_limit']/(1024*1024))}));
        return;
      };
      if (quota_issue == 'per_dive') {
        alert(I18n.t(["js","wizard","You have reached the default limit of %{count}Mb per dive. These files cannot be uploaded. Please downsize your files, or remove some pictures/videos from this dive, or ask for a bigger storage."], {count: Math.round(G_private_user['quota_limit']/(1024*1024))}));
        return;
      };

      if (hasPicture && diveboard.resizer.support()) {
        var resize_value = $(".diveboard-resizer-selector select").val();
        if(resize_value == "low"){
          uploader.resize_upload = true;
          uploader.resize_width = 640;
          uploader.resize_height = 480;
          qq.FileUploader.prototype._uploadFileList.call(uploader,files);
        }else if(resize_value == "high"){
          uploader.resize_upload = true;
          uploader.resize_width = 1600;
          uploader.resize_height = 1200;
          qq.FileUploader.prototype._uploadFileList.call(uploader,files);
        }else{
          uploader.resize_upload = false;
          uploader.resize_width = null;
          uploader.resize_height = null;

          var quota_issue = check_storage_quota(forecasted_size);
          if (quota_issue == 'per_user') {
            alert(I18n.t(["js","wizard","You have reached your quota of %{count}Gb. These files cannot be uploaded. Please remove image or video content from this dive or another."], {count: Math.round(G_private_user['quota_limit']/(1024*1024*1024)) }));
            return;
          };
          if (quota_issue == 'per_month') {
            alert(I18n.t(["js","wizard","You have reached the default limit of %{count}Mb of upload per month. These files cannot be uploaded. Please downsize your files, or ask for a bigger storage."], {count: Math.round(G_private_user['quota_limit']/(1024*1024))}));
            return;
          };
          if (quota_issue == 'per_dive') {
            alert(I18n.t(["js","wizard","You have reached the default limit of %{count}Mb per dive. These files cannot be uploaded. Please downsize your files, or remove some pictures/videos from this dive, or ask for a bigger storage."], {count: Math.round(G_private_user['quota_limit']/(1024*1024))}));
            return;
          };

          qq.FileUploader.prototype._uploadFileList.call(uploader,files);
        }

        /*$( "#dialog-resize-picture" ).dialog({
          resizable: false,
          modal: true,
          width: 550,
          zIndex: 99999,
          buttons: {
            "Full quality": function() {
              $( "#dialog-resize-picture" ).dialog("close");
              uploader.resize_upload = false;
              uploader.resize_width = null;
              uploader.resize_height = null;

              var quota_issue = check_storage_quota(forecasted_size);
              if (quota_issue == 'per_user') {
                alert('You have reached your quota of '+Math.round(G_private_user['quota_limit']/(1024*1024*1024))+'Gb. These files cannot be uploaded. Please remove image or video content from this dive or another.');
                return;
              };
              if (quota_issue == 'per_month') {
                alert('You have reached the default limit of '+Math.round(G_private_user['quota_limit']/(1024*1024))+'Mb of upload per month. These files cannot be uploaded. Please downsize your files, or ask for a bigger storage.');
                return;
              };
              if (quota_issue == 'per_dive') {
                alert('You have reached the default limit of '+Math.round(G_private_user['quota_limit']/(1024*1024))+'Mb per dive. These files cannot be uploaded. Please downsize your files, or remove some pictures/videos from this dive, or ask for a bigger storage.');
                return;
              };

              qq.FileUploader.prototype._uploadFileList.call(uploader,files);
            },
            "High quality\n(1600x1200)": function() {
              $( "#dialog-resize-picture" ).dialog("close");
              uploader.resize_upload = true;
              uploader.resize_width = 1600;
              uploader.resize_height = 1200;
              qq.FileUploader.prototype._uploadFileList.call(uploader,files);
            },
            "Medium quality\n(640x480)": function() {
              $( "#dialog-resize-picture" ).dialog("close");
              uploader.resize_upload = true;
              uploader.resize_width = 640;
              uploader.resize_height = 480;
              qq.FileUploader.prototype._uploadFileList.call(uploader,files);
            }
          }
        });*/
      } else {
        var quota_issue = check_storage_quota(forecasted_size);
        if (quota_issue == 'per_user') {
          alert(I18n.t(["js","wizard","You have reached your quota of %{count}Gb. These files cannot be uploaded. Please remove image or video content from this dive or another."], {count: Math.round(G_private_user['quota_limit']/(1024*1024*1024)) }));
          return;
        };
        if (quota_issue == 'per_month') {
          alert(I18n.t(["js","wizard","You have reached the default limit of %{count}Mb of upload per month. These files cannot be uploaded. Please downsize your files, or ask for a bigger storage."], {count: Math.round(G_private_user['quota_limit']/(1024*1024))}));
          return;
        };
        if (quota_issue == 'per_dive') {
          alert(I18n.t(["js","wizard","You have reached the default limit of %{count}Mb per dive. These files cannot be uploaded. Please downsize your files, or remove some pictures/videos from this dive, or ask for a bigger storage."], {count: Math.round(G_private_user['quota_limit']/(1024*1024))}));
          return;
        };

        qq.FileUploader.prototype._uploadFileList.call(uploader,files);
      }
    },
    _uploadFile: function(fileContainer){
      if (this.resize_upload && fileContainer.type.match(/image/)) {
        fileName = fileContainer.fileName != null ? fileContainer.fileName : fileContainer.name;

        var resize_div = $('<div class="file"><span class="qq-upload-file">'+fileName+'</span></div>');
        $('#wizard_resize_picture_list').append(resize_div);
        $('#wizard_resize_picture_list').show();
        $('#wizard_cancel_picture_list').show();
        image_resizer.resize_picture({
          file: fileContainer,
          max_width: this.resize_width,
          max_height: this.resize_height,
          start: function(){ resize_div.append('<span class="qq-upload-spinner"></span>');  },
          end: this._uploadCanvas(fileName, resize_div, this),
          error: function(){ resize_div.find('.qq-upload-spinner').hide(); resize_div.append('<span> : '+I18n.t(["js","wizard","Failed"])+'</span>'); },
          cancel: function(){ resize_div.detach(); }
        });
      } else {
        qq.FileUploader.prototype._uploadFile.call(this,fileContainer);
      }
    },
    _uploadCanvas: function(fileName, resize_div, saved_this) {
      return function(fileData){
        var id = saved_this._handler.add(fileData);

        var quota_issue = check_storage_quota(fileData.length);
        if (quota_issue == 'per_user')
          alert(I18n.t(["js","wizard","You have reached your quota of %{count}Gb. These files cannot be uploaded. Please remove image or video content from this dive or another."], {count: Math.round(G_private_user['quota_limit']/(1024*1024*1024)) }));
        if (quota_issue == 'per_month')
          alert(I18n.t(["js","wizard","You have reached the default limit of %{count}Mb of upload per month. These files cannot be uploaded. Please downsize your files, or ask for a bigger storage."], {count: Math.round(G_private_user['quota_limit']/(1024*1024))}));
        if (quota_issue == 'per_dive')
          alert(I18n.t(["js","wizard","You have reached the default limit of %{count}Mb per dive. These files cannot be uploaded. Please downsize your files, or remove some pictures/videos from this dive, or ask for a bigger storage."], {count: Math.round(G_private_user['quota_limit']/(1024*1024))}));
        if (quota_issue) {
          if (resize_div) resize_div.detach();
          image_resizer.cancel();
          if ($('#wizard_resize_picture_list .file').length == 0){
          $('#wizard_resize_picture_list').hide();
          if ($('#wizard_upload_picture_list:visible').length == 0)
            $("#wizard_cancel_picture_list").hide();
          }
          return;
        };

        if (saved_this._options.onSubmit(id, fileName) !== false){
            saved_this._onSubmit(id, fileName);
            saved_this._handler.upload(id, saved_this._options.params);
        }

        if (resize_div) resize_div.detach();
        if ($('#wizard_resize_picture_list .file').length == 0){
          $('#wizard_resize_picture_list').hide();
          if ($('#wizard_upload_picture_list:visible').length == 0)
            $("#wizard_cancel_picture_list").hide();
        }
      }
    },
    _setupDragDrop: function(){
      var self = this,
        dropArea = $(this._element).closest('.wizard-picture-add')[0];

      var dz = new qq.UploadDropZone({
        element: dropArea,
        onEnter: function(e){
          qq.addClass(dropArea, self._classes.dropActive);
          e.stopPropagation();
        },
        onLeave: function(e){
          e.stopPropagation();
        },
        onLeaveNotDescendants: function(e){
          qq.removeClass(dropArea, self._classes.dropActive);
        },
        onDrop: function(e){
          qq.removeClass(dropArea, self._classes.dropActive);
          self._uploadFileList(e.dataTransfer.files);
        }
      });
    }
  });
  G_picture_uploader = new qq.CustomizedFileUploader({
    // pass the dom node (ex. $(selector)[0] for jQuery users)
    element: $("#wizard_upload_picture_btn")[0],
    listElement: $("#wizard_upload_picture_list")[0],
    // path to server-side upload script
    action: '/api/picture/upload',
    // additional data to send, name-value pairs
    params: {
      'authenticity_token': auth_token,
      'user_id': G_owner_api.id
    },
    // validation
    // ex. ['jpg', 'jpeg', 'png', 'gif'] or []
    allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'tiff', 'tif', 'bmp', 'tga', 'xcf', 'psd', 'ai','svg', 'pcx',
                        'mpeg', 'avi', 'mov', 'webm', 'ogv', 'mp4', 'wmv', 'flv'],
    // each file size limit in bytes
    // this option isn't supported in all browsers
    sizeLimit: 0, //8192000, // max size
    //minSizeLimit: 0, // min size

    // set to true to output server response to console
    debug: false,
    template: '<div class="qq-uploader">' +
              '<div class="qq-upload-button">'+I18n.t(["js","wizard","Select photos from your computer"])+'</div>' +
              '</div>',


    // events
    // you can return false to abort submit
    onSubmit: function(id, fileName){
      $("#wizard_upload_picture_list").show();
      $("#wizard_cancel_picture_list").show();
    },
    onProgress: function(id, fileName, loaded, total){
      },
    onComplete: function(id, fileName, responseJSON){
      if (responseJSON.success) {
        $('#wizard_upload_picture_list li').each(function(i,e){
          if (e.qqFileId == id)
            $(e).hide();
        });
        if ( $('#wizard_upload_picture_list li:visible').length == 0) {
          $("#wizard_upload_picture_list").hide();
          if ($('#wizard_resize_picture_list:visible').length == 0){
            $("#wizard_cancel_picture_list").hide();
            if ($('#wizard_upload_picture_list:visible').length == 0)
              $("#wizard_cancel_picture_list").hide();
          }
        }
        $("#galleria-wizard").neat_gallery("append")(responseJSON.picture);
        create_edit_list();
        //TODO update dive_picture_data from neat_gallery
      }else{
        $("#galleria-wizard-loading").hide();
        $('#wizard_upload_picture_list li').each(function(i,e){
          if (e.qqFileId == id){
            console.log(responseJSON.message);
              $(e).find(".qq-upload-failed-text").html(responseJSON.message);
              $(e).find(".qq-upload-failed-text").show();
            }
        });
      }
    },
    onCancel: function(id, fileName){},
    messages: {
      // error messages, see qq.FileUploaderBasic for content
      typeError: I18n.t(["js","wizard","{file} has invalid extension. Only {extensions} are allowed."]),
      sizeError: I18n.t(["js","wizard","{file} is too large, maximum file size is {sizeLimit}."]),
      minSizeError: I18n.t(["js","wizard","{file} is too small, minimum file size is {minSizeLimit}."]),
      emptyError: I18n.t(["js","wizard","{file} is empty, please select files again without it."]),
      onLeave: I18n.t(["js","wizard","The files are being uploaded, if you leave now the upload will be cancelled."])
    },
    showMessage: function(message){ alert(message); }
  });

  //Adapt the interface if drag and drop is not supported
  $(".wizard-picture-notsupported").hide();
  $('.wzpic-feature').hide();
  if(!('draggable' in document.createElement('span'))) {
    $(".wizard-picture-dragtxt").hide();
    $(".wizard-picture-prefertxt").hide();
    $(".wizard-picture-notsupported").show();
    $(".wzpic-feature-dragdrop").show();
  }
  if (!("multiple" in document.createElement("input"))){
    $(".wizard-picture-notsupported").show();
    $(".wzpic-feature-multiple").show();
  }
  if (!diveboard.resizer.support()){
    $(".wizard-picture-notsupported").show();
    $(".wzpic-feature-resize").show();
  }

  $("#wizard_cancel_picture_list").click(reset_all_picture_upload);
}

function reset_all_picture_upload()
{
  image_resizer.cancel();
  $('#wizard_upload_picture_list .qq-upload-file').detach();
  $("#wizard_upload_picture_list .qq-upload-cancel").click();
  $("#wizard_cancel_picture_list").hide();
  $("#wizard_upload_picture_list").hide();
  $("#wizard_resize_picture_list").hide();
}





function check_storage_quota(forecast)
{
  if (typeof forecast == 'undefined') forecast = 0;

  //get the current storage that would be used for the pictures currently in the gallery
  var dive_storage = forecast;
  var uploaded_monthly = G_private_user['storage_used']['monthly_dive_pictures'] + forecast;
  var picture_list = $("#galleria-wizard").neat_gallery("list")();
  $.each(picture_list, function(i,e) {
    dive_storage += e['size'];
    if (e['just_uploaded'])
      uploaded_monthly += e['size'];
  });

  //take also into account the pictures being uploaded
  if (G_picture_uploader && G_picture_uploader._handler) {
    $.each(G_picture_uploader._handler.getQueue(), function(i,fileidx) {
      try {
        dive_storage += G_picture_uploader._handler.getSize(fileidx);
        uploaded_monthly += G_picture_uploader._handler.getSize(fileidx);
      } catch(e){}
    });
  }

  if (G_private_user['quota_type'] == 'per_dive' && dive_storage > G_private_user['quota_limit'])
    return 'per_dive';

  if (G_private_user['quota_type'] == 'per_month' && uploaded_monthly > G_private_user['quota_limit'])
    return 'per_month'

  if (G_private_user['quota_type'] == 'per_user' && uploaded_monthly > G_config['default_storage_per_month'] && G_private_user['storage_used']['dive_pictures'] - G_private_dive['storage_used'] + dive_storage > G_private_user['quota_limit'])
    return 'per_user';

  return null;
}



function check_fb_album_url(album_id){
  FB.api(album_id+"/photos", {limit: 500, access_token: G_user_fbtoken},function(response){
    if (!response || response.error) {
      diveboard.alert(I18n.t(["js","wizard","A technical error happened while trying to connect to Facebook."]));
    } else {
      add_album_from_facebook(response);
    }
  });
  /*
  $.ajax({
    url: "https://graph.facebook.com/v2.0/"+album_id+"/photos",
    dataType: 'jsonp',
    jsonpCallback: "add_album_from_facebook",
    data: ({
      access_token: G_user_fbtoken,
      limit: 500,
      callback: "add_album_from_facebook"
      }),
    error: function(data) { diveboard.alert("A technical error happened while trying to connect to Facebook."); },
    type: "GET"
  });*/
}
function add_album_from_facebook(data){
  if(data == false){
    alert(I18n.t(["js","wizard","Sorry, you do not have the rights on this album"]));
  }else{

    var new_images = [];
    for (var i=0; i < data.data.length; i++)
    {
      var photoURL = data.data[i].source;
      var link = data.data[i].link;
      new_images.push({id: "new_"+G_picture_cnt++, image: photoURL, link: link});
    }
    $("#wizard_pict_url").val("");
    bulk_add_newimage(new_images);
  }
}

function check_fb_pict_url(picture_id){
  FB.api(picture_id,{access_token: G_user_fbtoken}, function(response){
    if (!response || response.error) {
      diveboard.alert(I18n.t(["js","wizard","A technical error happened while trying to connect to Facebook."]));
    } else {
      add_image_from_facebook(response);
    }
  });
}

function add_image_from_facebook(data){
  if(data == false){
    alert(I18n.t(["js","wizard","Sorry, you do not have the rights on this picture"]));
  }else{
    var photoURL = data.source;
    var link = data.link;
    add_newimage({image: photoURL, link: link});
  }
}
function add_image_from_picasa(data){
  if(data == false){
    alert(I18n.t(["js","wizard","Sorry, you do not have the rights on this picture"]));
  }else{
    var photoURL = data.feed.media$group.media$content[0].url;
    var link = data.feed.link[1].href;
    add_newimage({image: photoURL, link: link});
  }
}

function find_album_from_picasa(data){
  if(data == false){
    alert(I18n.t(["js","wizard","Sorry, you do not have the rights on this picture"]));
  }else{
    for (var i=0; i < data.feed.entry.length; i++)
      for (var j=0; j < data.feed.entry[i].link.length; j++)
        //todo: make this comparison more robust !
        if (data.feed.entry[i].link[j].href == G_asked_album_url || (data.feed.entry[i].link[j].href.split("?")[0].match(new RegExp("/"+G_asked_album_url+"$", "i")) && G_asked_album_url.match(/[0-9]+/)))
        {
          $.ajax({
            url: data.feed.entry[i].id.$t.replace("/entry/", "/feed/"),
            dataType: 'jsonp',
            jsonpCallback: "add_album_from_picasa",
            data: ({
              alt: "json"
              }),
            error: function(data) { diveboard.alert(I18n.t(["js","wizard","A technical error happened while trying to connect to Picasa."])); },
            type: "GET"
          });
          return;
        }
  }
}

function picasa_user(data){
  if(data == false){
    alert(I18n.t(["js","wizard","Sorry, you do not have the rights on this album"]));
  }else{
    user_id = JSON.stringify(data.feed.link).match(/\"https:\/\/picasaweb.google.com\/([0-9]+)\"/)[1];
    G_asked_album_url= G_asked_album_url.replace("UID",user_id);

    $.ajax({
      url: "https://picasaweb.google.com/data/feed/api/user/"+user_id,
      dataType: 'jsonp',
      jsonpCallback: "find_album_from_picasa",
      data: ({
        alt: "json"
      }),
      error: function(data) { diveboard.alert(I18n.t(["js","wizard","A technical error happened while trying to connect to Picasa."])); },
      type: "GET"
    });
  }
}

function add_album_from_picasa(data){
  if(data == false){
    alert(I18n.t(["js","wizard","Sorry, you do not have the rights on this picture"]));
  }else{
    var new_photos = [];
    for (var k=0; k<data.feed.entry.length; k++)
    {
      var photoURL = data.feed.entry[k].media$group.media$content[0].url;
      var link = data.feed.entry[k].link[1].href;
      var thumbURL;
      try {
        thumbURL = data.feed.entry[k].media$group.media$thumbnail[data.feed.entry[k].media$group.media$thumbnail.length-1].url;
      } catch(e){}
      new_photos.push({id: "new_"+G_picture_cnt++, image: photoURL, thumb: thumbURL, link: link});
    }
    $("#wizard_pict_url").val("");
    bulk_add_newimage(new_photos);
  }
}

var flickrdata ="";
function add_image_from_flickr(data){
  flickrdata=data;
  if(data.stat == "fail"){
    alert(I18n.t(["js","wizard","Something went wrong... You may not have rights over this picture"]));
  } else{
    var photoURL = 'http://farm' + data.photo.farm + '.static.flickr.com/' + data.photo.server + '/' + data.photo.id + '_' + data.photo.secret + '.jpg';
    var link = data.photo.urls.url[0]._content;
    add_newimage({image: photoURL, link: link});
  }
}

function add_photoset_from_flickr(data){
  flickrdata=data;
  if(data.stat == "fail"){
    alert(I18n.t(["js","wizard","Something went wrong... You may not have rights over this picture"]));
  } else{
    var new_images=[];
    for (var i=0; i<data.photoset.photo.length; i++)
    {
      var photoURL = 'http://farm' + data.photoset.photo[i].farm + '.static.flickr.com/' + data.photoset.photo[i].server + '/' + data.photoset.photo[i].id + '_' + data.photoset.photo[i].secret + '.jpg';
      var link = data.photoset.photo[i].url_o || data.photoset.photo[i].url_m || data.photoset.photo[i].url_s || data.photoset.photo[i].url_t || data.photoset.photo[i].url_sq;
      new_images.push({id: "new_"+G_picture_cnt++,image: photoURL, link: link});
    }
    $("#wizard_pict_url").val("");
    bulk_add_newimage(new_images);
  }
}

function add_newimage(newimage, reload){
  var temp_id = Date.now().toString() + Math.round(Math.random()*100000);

  $("body").append($("<img id='"+temp_id+"' style='display:none;'/>"));
  $("#"+temp_id).load(function(){
    $("#galleria-wizard").neat_gallery("append")({id: "new_"+G_picture_cnt++, image:newimage.image, link:newimage.link});
    //if we just added the first picture, let's make it the favorite
    if (wizard_dive_pictures_data.length == 1) {
      set_favorite_picture_from_id(0);
    }
    create_edit_list();
    $("#"+temp_id).remove();
  });
  $("#"+temp_id).error(function(){
    diveboard.notify(I18n.t(["js","wizard","Error loading image"]),I18n.t(["js","wizard","Image with url :<br/>%{url}<br/>could not be loaded"], {url: newimage.image}), function(){});
    $("#"+temp_id).remove();
  });
  $("#"+temp_id).attr("src", newimage.image);
}

function bulk_add_newimage(newimage_array){
  $("#galleria-wizard").neat_gallery("append_list")(newimage_array);
  create_edit_list();
}

function base_58_decode(snipcode) {
  var alphabet = '123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ' ;
  var num = snipcode.length ;
  var decoded = 0 ;
  var multi = 1 ;
  for ( var i = (num-1) ; i >= 0 ; i-- )
  {
    decoded = decoded + multi * alphabet.indexOf( snipcode[i] ) ;
    multi = multi * alphabet.length ;
  }
  return decoded;
}

function del_current_image(){
  //TODO XXXX
  alert("TODO");
  return;

  //if the image deleted is the favorite picture, but we still have other pictures, then let's take the first as new favorite
  if (image_index == wizard_dive_pictures_favorite && wizard_dive_pictures_data.length > 0){
    set_favorite_picture_from_id(0);
  }
  else if (image_index == wizard_dive_pictures_favorite && wizard_dive_pictures_data.length == 0) {
    $("#favorite-picture-id").val("");
    $("#favoritepic").empty();
    $(".galleria-image").empty();
  }
  init_favorite_picture_id();
}

function set_favorite_picture(){
  set_favorite_picture_from_id(wizard_galleria.getIndex());
}

function set_favorite_picture_from_id(fav_id){
  wizard_dive_pictures_favorite = fav_id;
  $("#favorite-picture-id").val(wizard_dive_pictures_data[fav_id].image);
  init_favorite_picture_id();
}

function init_favorite_picture_id()
{
  var favorite_picture_url = $("#favorite-picture-id").val();
  $("#favoritepic").empty();
  var i=0;
  while (i<wizard_dive_pictures_data.length){
    if (wizard_dive_pictures_data[i].image == favorite_picture_url) {
      $("#favoritepic").html(I18n.t(["js","wizard","Favorite pic #%{n}"], {n: (i+1)})+" | ");
      wizard_dive_pictures_favorite = i;
    }
    i++;
  }
}

function allow_fb_search(){
  if( FB.getAccessToken() == null) {
    FB.login(function(response) {
      if (response.status == "connected") {
        G_user_fbtoken = FB.getAuthResponse().accessToken;
      } else {
        // user cancelled login
        alert(I18n.t(["js","wizard","Facebook needs you authenticated to allow for user search"]));
        $('.buddy_table').hide(); $('.buddy_db').show();
        return;
      }
    }, {});
  }else{
    G_user_fbtoken = FB.getAuthResponse().accessToken;
  }
}
function remove_buddy(ev){
  if(ev) ev.preventDefault();
  delete_buddy(this);
  return false;
}






function create_edit_list()
{
  var picture_list = $("#galleria-wizard").neat_gallery("list")();
  var temp_vals = {};

  $('#wizard-picture-list .wpl_bloc').each(function(idx, bloc){
    try{
      var tags =JSON.parse($(this).find('p.selected_species_list').attr("data"));
    }catch(e){var tags = undefined;}
    temp_vals[ bloc.id ] = {
      notes: $(this).find('.picture_notes').val(),
      tags: tags
    };
  });

  $('#wizard-picture-list').html('');

  $.each(picture_list, function(idx, data) {
    var content_id = "wizard_video_"+data.id;
    var clone = $('#wizard-picture-list-model').clone(false);
    clone.attr('id', 'wizard-picture-list-edit-'+data.id);

    $('#wizard-picture-list').append(clone);

    //displaying the image
    clone.find('.thumb_img').attr('src', data.image);
    var l_data = data;
    clone.find('.thumb_img').click(function(){ceebox_wizard_popup('', l_data)});

    //populating the text
    clone.find('.picture_notes').val( (typeof temp_vals['wizard-picture-list-edit-'+data.id] == 'undefined')?G_wizard_picture_notes[content_id]:temp_vals['wizard-picture-list-edit-'+data.id].notes );

    clone.find('p.selected_species_list').attr("data", (typeof temp_vals['wizard-picture-list-edit-'+data.id] == 'undefined')?JSON.stringify(G_wizard_picture_tags[content_id]):JSON.stringify(temp_vals['wizard-picture-list-edit-'+data.id].tags));
    update_picture_species_list_from_data(clone);


  });
}



////////////////////////////
//
//  OTHER
//
////////////////////////////

function add_safety_stop(){
  $("#profile_table").append($("#stop_def_tmpl").clone().show());
  return false;
}



function wizard_gmaps_init(editable){
  //CREATE GMAPS
  try {
    gmaps_initialize("wizardgmaps", editable);

    if (editable != $("#wizardgmaps").data("db-editable")) {
      $("#wizardgmaps").data("db-editable", editable);

      if (isNaN(parseFloat($("#spot-lat").val())) || isNaN(parseFloat($("#spot-long").val()))) {
        marker.setMap(null);
        $("#wizardgmaps_placepin").show();
        $("#wizardgmaps_removepin").hide();
      } else {
        marker.setMap(map);
        $("#wizardgmaps_placepin").hide();
        $("#wizardgmaps_removepin").show();
      }
      if (!editable) {
        $("#wizardgmaps_placepin").hide();
        $("#wizardgmaps_removepin").hide();
      }
    }


    google.maps.event.addListener(marker, 'dragend', function() {
      //infowindow.open(map,marker);
      map.setCenter(marker.position);
      var lat = marker.position.lat();
      var lng = marker.position.lng();
      $("#spot-lat").val(lat);
      $("#spot-long").val(lng);
      wizard_correct_dive = true;
      wizard_marker_moved = true;
      reverse_geocode();
    });
    wizard_maps_loaded = true;
  } catch(e){}
}

function wizard_gmaps_simmilar_spots(lat,lng,spot_id) {
	try {
    var image = new google.maps.MarkerImage('/img/marker_blue.png',
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
    var myLatLng = new google.maps.LatLng(lat,lng);
    var marker_2 = new google.maps.Marker({
        position: myLatLng,
        map: map,
        icon: image,
        shadow: shadow,
        draggable: false
      });
    google.maps.event.addListener(marker_2, 'click', function() {
        map.setCenter(marker_2.position);
        var lat = marker_2.position.lat();
        var lng = marker_2.position.lng();
        $("#spot-lat").val(lat);
        $("#spot-long").val(lng);
        wizard_marker_moved = true;
        select_spot(spot_id);
      });
    gmap_markers_simmilar.push(marker_2);
    //Adjust zoom to make sure marker is in viewport
    while (!map.getBounds().contains(marker_2.getPosition()) && map.getZoom()>1) {
    	map.setZoom(map.getZoom()-1);
    }
  } catch(e){
	  console.log(e.message);
  }
}

function wizard_gmaps_simmilar_highlightspot(lat, lng) {
	try {
	    var image = new google.maps.MarkerImage('/img/explore/marker_shop.png',
	    	      new google.maps.Size(15, 15),
	    	      new google.maps.Point(0,0),
	    	      new google.maps.Point(7, 7)
	    	    );
	    var myLatLng = new google.maps.LatLng(lat,lng);
	    marker_simmilar_highlight = new google.maps.Marker({
	        position: myLatLng,
	        map: map,
	        icon: image,
	        draggable: false
	      });
	  } catch(e){
		  console.log(e.message);
	  }
}

function wizard_gmaps_simmilar_highlightspotclear() {
	try {
	    if (marker_simmilar_highlight) {
	    	marker_simmilar_highlight.setMap(null);
	    }
	  } catch(e){
		  console.log(e.message);
	  }
}

function wizard_gmaps_clear_simmilar_spots() {
	try {
		for (var i = 0; i < gmap_markers_simmilar.length; i++) {
			gmap_markers_simmilar[i].setMap(null);
			gmap_markers_simmilar = [];
		}
	} catch(e){}
}


function update_gmaps_from_wizard_edit(execute_reverse_geocode) {
  if (!wizard_maps_loaded)
    wizard_gmaps_init(true);

  	wizard_correct_dive = true;
  
	//simply update the map to the input coords
	var lat = parseFloat($("#spot-lat").val());
	var lng = parseFloat($("#spot-long").val());
	if (!isNaN(lat)&&!isNaN(lng)) {
	  $("#wizardgmaps_placepin").hide();
	  $("#wizardgmaps_removepin").show();
	  var latlng = new google.maps.LatLng(lat, lng);
	  marker.setMap(map);
	  marker.setPosition(latlng);
	  map.setCenter(marker.position);
	  update_species_list(Number($("#spot-lat").val()), Number($("#spot-long").val()));
	  if (execute_reverse_geocode) {
	  	reverse_geocode();
	  }
	}
	else {
	  $("#wizardgmaps_placepin").show();
	  $("#wizardgmaps_removepin").hide();
	  marker.setMap(null);
	}
}

function show_flag(){

  var code = country_code_from_name($("#spot-country").val());
    if (code != "")
    {
      $("#wizard-spot-flag").attr("src","/img/flags/"+code.toLowerCase()+".gif");
      $("#spot-country").attr("shortname",code.toLowerCase());
      $("#spot-country").val(country_name_from_code(code));
    }
    else
    {
      $("#spot-country").attr("shortname","");
      $("#wizard-spot-flag").attr("src","/img/flags/blank.gif");
    }
}

var G_wizard_values;
function wizard_store_default()
{
  G_wizard_values = [];
  $(".editable_input").each(function(index, element){
    if ($.inArray(element.tagName, ['INPUT', 'TEXTAREA', 'SELECT'])>=0)
      G_wizard_values.push({elt: element, val: $(element).val(), checked: $(element).attr('checked')});
    else
      G_wizard_values.push({elt: element, html: $(element).html()});
  });
}

function wizard_reset_ui_controls()
{
  try {
    //Autocomplete for trip names
    $("#wizard-trip").example(I18n.t(["js","wizard","E.g. Hawai 2011"]));
    $("#wizard-trip").autocomplete({source:G_all_trip_names});

    //Autocomplete for gear
    $("#add_gear_manufacturer").example(I18n.t(["js","wizard","Manufacturer"]));
    $("#add_gear_model").example(I18n.t(["js","wizard","Model"]));
    $("#add_gear_manufacturer").autocomplete({source:list_of_manufacturers});
 	
 	//Setup country
    $("#spot-country").removeClass('ui-autocomplete-input');
    $("#spot-country").addClass('ui-autocomplete-input example');

    $("#spot-country").autocomplete({  source : countries,
      select: function(event, ui) {
        //get spot details and show them
        //selected is ui.item.id
        $("#wizard-spot-flag").attr("src","/img/flags/"+ui.item.name.toLowerCase()+".gif");
        $("#spot-country").attr("shortname",ui.item.name.toLowerCase());
      $( "#spot-location" ).autocomplete( "option", "source","/api/search/location.json?ccode="+$("#spot-country").attr("shortname").toUpperCase());
      update_gmaps_from_wizard_edit(false);
      },
      close: function(event, ui){
      show_flag();
      },
      autoFill:true
    });

    $("#diveshop-search").autocomplete({ minLength: 2,
      source: function(request, response){
        $.ajax({
          url:"/api/search/shop.json",
          data:({
            q: request.term
          }),
          dataType: "json",
          success: function(data){
            response( $.map( data, function( item ) {
              console.log(item);
              var label = "<span>";
              if (item.picture)
                label += "<img src='"+item.picture+"' class='shop_picker_list_logo'/>";
              else
                label += "<div class='shop_picker_list_logo'/>";
              label += item.name;
              label += "</span>"
              label += "<span class='shop_picker_list_location'><img src='/img/flags/"+item.country_code.toLowerCase()+".gif'/>";
              if (item.country)
                label += item.country;
              if (item.country && item.city)
                label += ", ";
              if (item.city)
                label += item.city;
              label += "</span>";

              return {
                label: "<span class='shop_picker_list_span'>"+label+"</span>",
                value: item.value,
                picture: item.picture,
                web: item.web,
                home: item.home,
                relative: item.relative,
                id: item.id
              }
            }));
          },
          error: function(data) { diveboard.alert(I18n.t(["js","wizard","A technical error happened while trying to connect to Facebook."])); }
        });
      },
      select: function(event, ui){
        $(".wz_shop_line_found").show();
        $(".wz_shop_line_search").hide();
        $(".wz_shop_line_create").hide();
        $("#wz_shop_found_id").val(null);
        $("#wz_shop_found_name").text("");
        $("#wz_shop_found_url").text("");
        $("#wz_shop_found_url").attr('href', "");
        $("#wz_shop_found_id").val(ui.item.id);
        $("#wz_shop_found_name").text(ui.item.value);
        if(ui.item.web!=null){
        $("#wz_shop_found_url").text(ui.item.web);
        $("#wz_shop_found_url").attr('href', ui.item.web);
        }
        $(".wz_shop_home").attr('href', ui.item.relative);
        $("#signing_shop_request").removeAttr("READONLY").prop("checked", true);
        if (ui.item.has_review) {
          $('.wz_shop_line_with_review').show();
          $('.wz_shop_line_without_review').hide();
        } else {
          $('.wz_shop_line_with_review').hide();
          $('.wz_shop_line_without_review').show();
        }
      }
    });

    $("#buddy-db-name").autocomplete({
      source: function(request, response){
        $.ajax({
          url:"/api/search/user.json",
          data:({
            q: request.term
          }),
          dataType: "json",
          success: function(data){
            console.log ("plop");
            response( $.map( data, function( item ) {
              return {
                label: "<img src='"+item.picture+"' class='buddy_picker_list'/>"+"<span class='buddy_picker_list_span'>"+item.label+"</span>",
                value: item.value,
                db_id: item.db_id,
                picture: item.picture
              }
            }));
          },
          error: function(data) { diveboard.alert(I18n.t(["js","wizard","A technical error happened while trying to connect to Facebook."])); }
        });
      },
      minLength: 2,autoFocus: true,
      select: function(event, ui){
        $("#buddy-db-name-hidden").attr("db_id", ui.item.db_id);
        $("#buddy-db-name-hidden").attr("name", ui.item.value)
        $("#buddy-db-name-hidden").attr("picture", ui.item.picture);
        add_buddy();
        $("#buddy-db-name-hidden").attr("db_id", "");
        $("#buddy-db-name-hidden").attr("name", "");
        $("#buddy-db-name-hidden").attr("picture", "");

        },
      close: function(event, ui){$("#buddy-db-name").val("");}
    });
    $("#buddy-db-name").change(function(ev){
      ev.preventDefault();
      $("#buddy-db-name-hidden").attr("db_id", "");
      $("#buddy-db-name-hidden").attr("name", "");
    })

    $("#buddy-fb-name").change(function(ev){
      ev.preventDefault();
      $("#buddy-fb-name-hidden").attr("fb_id", "");
      $("#buddy-fb-name-hidden").attr("name", "");
    })

    $.ui.autocomplete.prototype._renderItem = function (ul, item) {
      item.label = item.label.replace(new RegExp("(?![^&;]+;)(?!<[^<>]*)(" + $.ui.autocomplete.escapeRegex(this.term) + ")(?![^<>]*>)(?![^&;]+;)", "gi"), "<strong>$1</strong>");
      return $("<li></li>")
        .data("item.autocomplete", item)
        .append("<a>" + item.label + "</a>")
        .appendTo(ul);
    };

    //reset search field
    $("#spotsearch").example(I18n.t(["js","wizard","Amphorae's Cave, Cyprus"]));
    $("#spotsearch").removeClass('ui-autocomplete-input');
    $("#spotsearch").addClass('ui-autocomplete-input example');
    $("#spotsearch").example(I18n.t(["js","wizard","Example : White River, Cyprus"]));
    $("#spotsearch").autocomplete({
      source: function(request, response){
        console.log("request: "+JSON.stringify(request));
        $.ajax({
          url: '/api/search/spot',
          data: {q: request.term.replace(new RegExp("</*strong>","gi"), "")},
          success: function(data){
            response($.map(data.data, function(item){return {label: item.name , value: item.name, id: item.id } }));
          }
        });
      },
      select: function(event, ui) {
        //get spot details and show them
        //selected is ui.item.id
        select_spot(ui.item.id);
      },
      autoFill:true, minLength: 3
    });
    $.ui.autocomplete.prototype._renderItem = function (ul, item) {
      var was = item.label;
      var all_terms = this.term.replace(new RegExp("[^ ,;:\r\t\na-zA-Z\d\s:]","gi"),"").split(/[ ,;:\r\t\n]+/);
      item.label = item.label.replace(new RegExp("</*strong>","gi"), ""); //cleanup from previous highlights
      for (var idx in all_terms)
      {
        item.label = item.label.replace(new RegExp("(?![^&;]+;)(?!<[^<>]*)(" + $.ui.autocomplete.escapeRegex(all_terms[idx]).replace(/[^a-zA-Z0-9]/g, '.?') + ")(?![^<>]*>)(?![^&;]+;)", "gi"), "<strong>$1</strong>");

      }
      //console.log("adding from:"+was+"to:"+item.label);
      return $("<li></li>")
        .data("item.autocomplete", item)
        .append("<a>" + item.label + "</a>")
        .appendTo(ul);
    };

    //reset file uplaoder
    $("#dive_list_selector").hide();
    $("#dive_list_selected").empty();
    $(".manual_creation").show();
    $("#dive_list_selected").empty();
    $("#wizard_plugin_uploader").hide();

    $(".manual_creation").show();
  } catch(e){
    track_exception_global(e);
  }
}

function wizard_reset_default()
{
  //Clone the private dive data
  G_current_private_dive = $.extend({}, G_private_dive);
  G_current_private_user = $.extend({}, G_private_user);
  if (!G_current_private_dive['dan_data'] && !G_current_private_dive['dan_data_sent']) {
    G_current_private_dive['dan_data'] = dan_form_to_hash($('.dan_form'));
  }
  if (G_current_private_dive['dan_data'] && G_current_private_user['dan_data'])
    G_current_private_dive['dan_data']['diver'] = G_current_private_user['dan_data']

  //Reset the standard input fields having the "editable_input" class
  $.each(G_wizard_values, function(index, element){
    if ('val' in element) {
      $(element.elt).val(element.val);
      $(element.elt).attr('checked', element.checked);
    } else if ('html' in element){
      $(element.elt).html(element.html);
    }
  });

  wizard_reset_ui_controls();

  reset_spot_details();

  //reset plugin uploader
  wizard_plugin_cancel();

  //reset dive profile data
  if (G_has_profile != "") {
    delete_profile_data(); // clean-up time
    $("#profile-updated").val("");
    $("#profile-fileid").val("");
    $("#profile-diveid").val("");
    $("#wizard_delete_graph").show();
    $("#wizard_add_profile").hide();
    $("#wizard_graph").show();
    wizard_profile_display();// needed to recreate the graph that we carelessly destroyed by delete_profile_data or regenerate if it was modified
  } else {
    delete_profile_data(); // clean-up time
    $("#profile-updated").val("");
    $("#profile-fileid").val("");
    $("#profile-diveid").val("");
    G_this_dive_data = "";
    G_this_dive_labels = "";
    G_this_alarm_data = "";
    G_this_dive_unit = "";
  }
  $(".manual_creation").show();


  //backup the initial state of G_dive_fish
  G_dive_fishes_backup = G_dive_fishes.slice(0);

  //reset galleria
  $("#galleria-wizard").replaceWith("<div id='galleria-wizard'></div>");
  wizard_galleria = "";
  wizard_galleria_initialized = false;
  wizard_initialize_galleria();

  //reset DAN form
  if (G_current_private_dive['dan_data'])
    hash_to_dan_form(G_current_private_dive['dan_data'], $('.dan_form'));
  else if (G_current_private_dive['dan_data_sent'])
    hash_to_dan_form(G_current_private_dive['dan_data_sent'], $('.dan_form'));
  check_dan_form_status(G_current_private_dive['dan_data'], G_current_private_dive['dan_data_sent'], false);
}


function wizard_friend_picker_clicked(){
  $("#friendsearch").after('<div class="facebook-auto"><div class="default" style="display: block;">'+I18n.t(["js","wizard","Start to type a Facebook username..."])+'</div></div>');

}


/////////////////////////
//
// PLUGIN DIALOG && PROFILE
//
/////////////////////////

function wizard_computer_show_instructions(){
  //show the instruction
  var computer_selected1 = $("#wizard_computer_select1 option:selected").text().replace(/[^A-Za-z0-9]/g,"");
  var computer_selected2 = $("#wizard_computer_select2 option:selected").text().replace(/[^A-Za-z0-9]/g,"");

  $("#wizard_computer_instructions1 div").hide();
  $("#wizard_computer_instructions2 div").hide();

  if ($("#wizard_computer_select1").val() != "XXX")
  {
    $("#wizard_computer_instructions1 .Instructions_"+computer_selected1).show();
    $("#wizard_computer_instructions1").show();
  }
  else
  {
    $("#wizard_computer_instructions1").hide();
  }
  if ($("#wizard_computer_select2").val() != "XXX")
  {
    $("#wizard_computer_instructions2 .Instructions_"+computer_selected2).show();
    $("#wizard_computer_instructions2").show();
  }
  else
  {
    $("#wizard_computer_instructions2").hide();
  }
}



function setup_upload_udcf_file(){
  var uploader = new qq.FileUploader({
    // pass the dom node (ex. $(selector)[0] for jQuery users)
    element: $("#wizard_upload_btn")[0],
    // path to server-side upload script
    action: '/api/udcfupload.json',
    // additional data to send, name-value pairs
    params: {
      dive_id: $("#dive-id").val(),
      user_id: G_owner_id,
    'authenticity_token': auth_token
    },
    // validation
    // ex. ['jpg', 'jpeg', 'png', 'gif'] or []
    allowedExtensions: [],
    // each file size limit in bytes
    // this option isn't supported in all browsers
    sizeLimit: 15242880, // max size
    //minSizeLimit: 0, // min size

    // set to true to output server response to console
    debug: false,

    // events
    // you can return false to abort submit
    onSubmit: function(id, fileName){
      //clean-up the mess....
      //$(".qq-upload-list").empty();
    },
    onProgress: function(id, fileName, loaded, total){ console.log('XXX:' +loaded); },
    onComplete: function(id, fileName, responseJSON){
      if (responseJSON["success"] == "false" ||responseJSON["success"] == false|| responseJSON["success"] == undefined) {
        $(".qq-upload-failed-text").show();
        diveboard.notify(I18n.t(["js","wizard","Profile upload"]), I18n.t(["js","wizard","Sorry, the file you uploaded was not recognised. Diveboard currently only supports UDCF, DAN DL7, Uwatec ASD, Suunto SDE or Cressi txt files.<br/><br/><b>Scubapro/Uwatec SmartTrak users:</b><br/>Please note that if you're using <b>SmartTrak version 2.08</b> you need to upgrade to 2.0801 from <a href='http://www.scubapro.com' target='_blank'>scubapro.com</a>."]));
      }else{
        console.log($(".qq-upload-list"));
        wizard_dive_all_summary = responseJSON["dive_summary"];

        if (responseJSON["nbdives"] == "1" && !wizard_bulk && $(".qq-upload-list").children().length==1){
          //only one dive - let's update the page
          $("#profile-updated").val("update");
          $("#profile-fileid").val(responseJSON["fileid"]);
          $("#profile-diveid").val(0);
          wizard_dive_selected_summary = wizard_dive_all_summary[0];
          show_profile_uploaded();
        }else{
          set_dive_picker(responseJSON);
        }

      }
      $(".qq-upload-list").empty();
    },
    onCancel: function(id, fileName){},

    messages: {
      // error messages, see qq.FileUploaderBasic for content
      typeError: I18n.t(["js","wizard","Sorry, {file} has invalid extension. Only {extensions} are allowed."]),
      sizeError: I18n.t(["js","wizard","Sorry, {file} is too large. The maximum file size is {sizeLimit}."]),
      minSizeError: I18n.t(["js","wizard","Sorry, {file} is too small. The minimum file size is {minSizeLimit}."]),
      emptyError: I18n.t(["js","wizard","Sorry, {file} is empty, please select files again without it."]),
      onLeave: I18n.t(["js","wizard","The files are being uploaded, if you leave now the upload will be cancelled."])
    },
    showMessage: function(message){
      try {
        if (message && message.length > 0) {
          diveboard.notify(I18n.t(["js","wizard","Profile upload"]), message);
        }
      }catch(e){}
    }
  });

}

var dive_wizard_picker_setup = false;

function set_dive_picker(responseJSON){
    //COMMON CLASS for computer or UDCF upload
    //many dives to chosse from - let's show the picker
    console.log(responseJSON);
    console.log(wizard_bulk);
    $("#dive_list_selected").empty();
    $("#dive_list_enhanced_actions").empty();
    if (!wizard_bulk){
      $("#dive_list_selected").show();
      $("#dive_list_enhanced_actions").hide();
      $("#dive_fileid").val(responseJSON["fileid"]);
      //var dive_summary=[];
      for (var i=0; i<responseJSON["nbdives"]; i++)
      {
        var value = responseJSON.dive_summary[ i ];
        //dive_summary = responseJSON["dive_summary"][i];
        var to_append = "<option value=\""
        if(value["number"]!=null) to_append+=value["number"]+"\">";
        if(value["date"]!=null && value["time"]!=null && value["duration"]) to_append+=value["date"]+" "+value["time"]+" "+value["duration"]+I18n.t(["js","wizard","mins"])+" "
        if(value["max_depth"]!=null)to_append+=unit_distance(value["max_depth"],true)
        to_append+="</option>"
        $("#dive_list_selected").append(to_append);
      }
      $("#wizard_add_profile").hide();
      $(".manual_creation").hide();
      $("#dive_list_selector").show();
      $("#wizard2_next").hide();
    }else{
      $("#dive_fileid").val(responseJSON["fileid"]);
      //var dive_summary=[];
      if (!dive_wizard_picker_setup){
        $("#dive_list_selected").attr("multiple","true");
        $("#dive_list_selected").attr("size","10");
        $("#dive_list_selected_info").show();
        $("#dive_list_selector_button").html(I18n.t(["js","wizard","Import dives"])+' <img style="display:none;" src="/img/loading.gif"/>');
        $(".append_to_dive_list").live('change', change_dive_picker_options);
        $(".dive_list_radio").live('change', change_dive_radio_picker);
        G_private_dives_digest_hash = {}
        $.each(G_private_dives_digest, function(idx, el){
          G_private_dives_digest_hash[el.id] = el;
        });
        G_user_skipped_dives_hash={}
        $.each(G_user_skipped_dives, function(idx, el){
          G_user_skipped_dives_hash[el] = true;
        });
        dive_wizard_picker_setup = true;
      }

      $("#dive_list_selected").hide();
      $("#dive_list_enhanced_actions").show();

      responseJSON.dive_summary = responseJSON.dive_summary.sort(function(a,b){return (new Date(b.date))-(new Date(a.date))}); //Sort the mess so latest dives come first


      $("#dive_list_enhanced_actions").html(tmpl("dive_list_enhanced_actions_template",responseJSON));
      $("#wizard_add_profile").hide();
      $(".manual_creation").hide();
      $("#dive_list_selector").show();
      $("#wizard2_next").hide();
    }
}

function build_dive_picker_options(id){
  var myoptions = "<select class='append_to_dive_list'>";
  myoptions += "<option value=''>---</option>";
  $.each(G_private_dives_digest, function(idx, el){
    myoptions +="<option value=\""+el.id+"\"";
    if(id == el.id){
      myoptions += " SELECTED ";
    }
    myoptions +=">"+el.date.split(/[TZ]/)[0]+" "+el.date.split(/[TZ]/)[1]+" "+el.duration+I18n.t(["js","wizard","mins"])+" "+unit_distance(el.maxdepth,true);
    if (el.has_uploaded_profile){
      myoptions +=" "+I18n.t(["js","wizard","has profile"]);
    }
    myoptions +="</option>";
  });
  myoptions+="</select>";
  return myoptions;
}

function dive_details_compute_digest(d){
  return (d.date+"T"+d.time+"Z/"+d.duration+"/"+d.max_depth);
}

function change_dive_picker_options(e){
  if ($(e.target).val() == ""){
    //do nothing
    $(e.target).parent().parent().find("input[value='do_nothing']").attr("CHECKED", true);
  }else{
    //select append to
    $(e.target).parent().parent().find("input[value='append_to_dive']").attr("CHECKED", true);
  }
}

function change_dive_radio_picker(e){
  if ($(e.target).attr("value") != "append_to_dive" ){
    $(e.target).parent().parent().find("select").val("");
  }
  if ($(e.target).attr("value") == "do_nothing" ){
    $(e.target).attr("force_skip", true);
  }
}

function extract_dive_bulk_upload_data(){
  var actions = [];
  $.each($("#dive_list_enhanced_actions .dive_list_enhanced_entry"), function (idx, el){
    var radio = $("input[type=radio][name=dive_list_radio_"+$(el).attr("data")+"]:checked");
    if(radio.val() == "do_nothing"){
      if(radio.attr("force_skip") == "true" && $(el).attr("source") == "computer")
        actions.push({id: $(el).attr("data") ,action: "do_nothing", force_skip: true, digest: $(el).attr("digest")});
    }else if(radio.val() == "append_to_dive"){
      actions.push({id: $(el).attr("data") ,action: "append_to_dive", dive_id: $(el).find("select").val()});
    }else{
      actions.push({id: $(el).attr("data") ,action: "new_dive"});
    }
  });
  return actions.reverse(); //we want older actions to be treated first , dives are sorted by date
}
function movescount_popup(){
      var data= $("#callMovescountPopup").attr('data') || $("#importMovescountDives").attr('data');
      var pop=window.open(data,"","width=1000, height=500");
      console.log(data);
      var check_fnt=setInterval(
        function(){
          if($(pop.document).contents().find('body').html()=="Movescount account has successfully been linked.You are going to be redirected"){
            pop.close();
            clearInterval(check_fnt);
            get_profile_from_movescount();
          }
          if(pop==undefined){
            clearInterval(check_fnt);
          }
        }, 500);
      
    };
function get_profile_from_movescount(ev){
  diveboard.mask_file(true);
  $.ajax({
    url: "/api/v2/movescount_dives",
    data: ({}),
    type: "POST",
    dataType: "json",
    error: function(data) { 
      diveboard.unmask_file();
      diveboard.alert(I18n.t(["js","wizard","A technical error happened while creating the dive from the uploaded profile."])); 
    },
    success: function(data) {
      console.log(data);
      diveboard.unmask_file();
      if(data['success']){
        wizard_dive_all_summary = data["data"]["dive_summary"];
        set_dive_picker(data.data);
      }
      else{
        movescount_popup();
      }
    }
  });
}
function get_profile_from_file(ev){
  ev.preventDefault();

  if (wizard_bulk){
    var bulk_actions = extract_dive_bulk_upload_data();
  }else{
    var bulk_actions = []
  }

  // prevent to call the API if no dive has been selected
  if (($("#dive_list_selected").val() == null && wizard_bulk==false) ||(wizard_bulk == true && bulk_actions.length == 0))  {
    $( "#dialog-nodiveselected" ).dialog({
      resizable: false,
      modal: true,
      zIndex: 99999,
      buttons: {
        "OK": function() {
        $( this ).dialog( "close" );
        }
      }
    });
    $(".ui-dialog").position({
   my: "center",
   at: "center",
   of:".ui-widget-overlay"
});
    return;
  }

  $("#dive_list_selector_button").unbind();
  $("#dive_list_selector_button").click(function(ev){ev.preventDefault();})
  $("#dive_list_selector_button img").show();

  if (wizard_bulk)
    ga('send','event', 'Wizard', 'Bulk Dives imported - Start', G_W_model, bulk_actions.length);
  else
    ga('send', 'event', 'Wizard', 'Single Dives imported - Start', G_W_model, $("#dive_list_selected").val().length);



  $.ajax({
    url: "/api/divefromtmp.json",
    data: ({
      'authenticity_token': auth_token,
      //add difference between create and update
      fileid: $("#dive_fileid").val(),
      user_id: G_owner_api.id,
      dive_number: $("#dive_list_selected").val(),
      bulk: wizard_bulk,
      bulk_actions: JSON.stringify(bulk_actions)
    }),
    type: "POST",
    dataType: "json",
    error: function(data) { diveboard.alert(I18n.t(["js","wizard","A technical error happened while creating the dive from the uploaded profile."])); },
    success: function(data) {
      if (wizard_bulk){
        ga('send', 'event', 'Wizard', 'Bulk Dives imported - OK', G_W_model, bulk_actions.length);
        //no need to adding back the listener since the wizard is killed by relaoding page
        location.replace("/"+G_owner_vanity_url+"/");
      }else{
        ga('send', 'event', 'Wizard', 'Single Dives imported - OK', G_W_model, $("#dive_list_selected").val().length);
        //save the dive data
        $("#profile-updated").val("update");
        $("#profile-fileid").val($("#dive_fileid").val());
        $("#profile-diveid").val($("#dive_list_selected").val());
        for (var i in wizard_dive_all_summary) {
          if (wizard_dive_all_summary[i]["number"] == $("#dive_list_selected").val()){
            wizard_dive_selected_summary = wizard_dive_all_summary[ i ];
            }
        }
        if(wizard_dive_selected_summary["max_depth"]==null){
          parser=new DOMParser();
          xmlDoc=parser.parseFromString(data["divedata"],"text/xml");
          d=xmlDoc.getElementsByTagName('D');
          max_depth=0;
          for(i=0;i<d.length;i++){
            x=d[i].childNodes[0];
            depth=x.nodeValue;
            console.log(depth);
            if(depth>max_depth){
              max_depth=depth;
            }
          }
          wizard_dive_selected_summary["max_depth"]=max_depth;
        }
        show_profile_uploaded();
        $("#wizard2_next").show();
        //we add back the listener
        $("#dive_list_selector_button").unbind();
        $("#dive_list_selector_button").click(get_profile_from_file);
        $("#dive_list_selector_button img").hide();
      }
    }
  });
}

function unselect_all_bulk(e){
  if(e)
    e.preventDefault();
  $(".dive_list_radio[value='do_nothing']").click();
}


function show_profile_uploaded(){
  $("#dive_list_selected").empty();
  $("#wizard_add_profile").hide();
  $("#wizard_delete_graph").show();
  $(".manual_creation").show();
  $("#dive_list_selector").hide();

  //Setting the basic info for the dive

  $("#wizard-date").val( wizard_dive_selected_summary["date"] );
  $("#wizard-time-in-hrs").val( wizard_dive_selected_summary["time"].split(':')[0] );
  $("#wizard-time-in-mins").val( wizard_dive_selected_summary["time"].split(':')[1] );
  $("#wizard-max-depth").val( unit_distance(wizard_dive_selected_summary["max_depth"], false) );
  $("#wizard-duration-mins").val( wizard_dive_selected_summary["duration"] );
  if (wizard_dive_selected_summary["maxtemp"])
    $("#wizard-surface-temperature").val( unit_temp(wizard_dive_selected_summary["maxtemp"], false) );
  if (wizard_dive_selected_summary["mintemp"])
    $("#wizard-bottom-temperature").val( unit_temp(wizard_dive_selected_summary["mintemp"], false) );

  $('#wizard_graph').html('<div style=" margin-left: auto; margin-right: auto;" id=wizard_dive_profile ></div>');
  $("#wizard_graph").show();
  load_tmpsvg_into("#wizard_dive_profile", $("#profile-fileid").val(), $("#profile-diveid").val(), "big_blue");
  $("#wizard2_next").show();
  divecomplete();
  wizard_plugin_retry();
}

function wizard_profile_display()
{
  load_divesvg_into("#wizard_graph", "big_blue");
}


function delete_profile_data(e){
  if(e)
    e.preventDefault();

  G_wizard_dive_data = "";
  G_wizard_dive_labels = "";
  G_wizard_alarm_data = "";
  G_wizard_dive_unit = "";
  $("#profile-updated").val("delete");
  $("#profile-fileid").val("");
  $("#profile-diveid").val("");
  $('#wizard_graph').empty();
  $('#wizard_graph').hide();
  $("#dive_list_selected").empty();
  show_profile_data_uploader();

}

function show_profile_data_uploader(){
  $("#wizard_delete_graph").hide();
  $("#wizard_plugin_uploader").hide();
  $("#wizard_add_profile").show();
  $("#dive_list_selector").hide();
  $(".manual_creation").show();
  $("#dive_list_selected").empty();
  $("#wizard2_next").show();
  $("#wizard_computer_select1").val(I18n.t(["js","wizard","Select your computer model.."]));
  if (wizard_bulk){
    $("#profile_table").hide();
    $("#wizard2_next").hide();
  }

}



///////////////////////
//
// BULK MANAGER
//
///////////////////////

function sort_dives(attr, order) {

  function sort_order(a,b){
    var r = 1;
    if (order == 'DESC')
      r=-1;

    var val_a = $(a).find(attr).text();
    var val_b = $(b).find(attr).text();

    if (diveboard.isNumeric(val_a) && diveboard.isNumeric(val_b)){
      val_a = parseInt(val_a);
      val_b = parseInt(val_b);
    }

    if (val_a > val_b)
      return(r);
    else if (val_a == val_b) {
      if ($(a).find('.exitem_date').text() > $(b).find('.exitem_date').text())
        return(r);
      else
        return(-r);
    }

    else
      return(-r);
  }

  var all_items = $(".export_list_item").detach();
  all_items.sort(sort_order);
  all_items.each(function(idx, elt){ $("#wizard_export_list").append(elt);  });


}

function request_export(format) {
  list_of_dives = [];

  $("#wizard_export_list input:checked").each(function(index, value) {
    list_of_dives.push(value.name);
  });

  if (list_of_dives.length == 0){
    alert(I18n.t(["js","wizard","You must select at least one dive to export"]));
    return;
  }

  location.replace("/api/export_dives."+format+"?listDives="+list_of_dives);
}

function request_export_zxl() {
  request_export("zxl");
}

function request_export_udcf() {
  request_export("udcf");
}

function request_bulk_privacy(privacy){
  list_of_dives = [];

  $("#wizard_export_list input:checked").each(function(index, value) {
    list_of_dives.push(value.name);
  });

  if (list_of_dives.length == 0){
    alert(I18n.t(["js","wizard","You must select at least one dive to update privacy"]));
    return;
  }

  $("#tab_bulklist_content").html('<img src="/img/transparent_loader.gif" style="margin-left: 40%; margin-top: 25% " alt="#">');
  $.ajax({
    url: "/api/update_privacy_dives",
    data: ({
      listDives: list_of_dives,
      privacy: privacy
    }),
    type: "GET",
    dataType: "json",
    error: function(data) {
      diveboard.alert(I18n.t(["js","wizard","A technical error happened while updating the dives."]), null, function(){
        $("#tab_bulklist_content").load('/api/bulklisting?owner_id='+G_owner_api.id, {selected_dives:list_of_dives.toString()}, function(response, status, xhr){});
      });
    },
    success: function(data) {
      if (data.success){
        $("#tab_bulklist_content").load('/api/bulklisting?owner_id='+G_owner_api.id, {selected_dives:list_of_dives.toString()}, function(response, status, xhr){});
        $.each(data.updated, function(index, value){
          $("#wizard_export_list [name='"+value+"']").attr("privacy", data.privacy);
          if(data.privacy == 0)
            $("#dive"+value+" .dive_bullet_column div").addClass("dive_bullet").removeClass("dive_bullet_private");
          else
            $("#dive"+value+" .dive_bullet_column div").removeClass("dive_bullet").addClass("dive_bullet_private");
          });
          if(data.not_updated.length>0){
            diveboard.mask_file(false);
             diveboard.notify(I18n.t(["js","wizard","Success with warning"]), "<span style='color: green' class='symbol'>.</span> "+I18n.t(["js","wizard","Dives successfully updated except for dive(s) with id(s) %{ids} which could not be made public.<br/>This usually means spot information is missing."], {ids: data.not_updated.toString().replace(/,/g,", ")}), function(){
              diveboard.unmask_file();
             });

          }
      }
      else
        diveboard.alert(I18n.t(["js","wizard","A technical error happened while updating the dives."]), null, function(){
          $("#tab_bulklist_content").load('/api/bulklisting?owner_id='+G_owner_api.id, {selected_dives:list_of_dives.toString()}, function(response, status, xhr){});
        });
    }
  });
}



function request_bulk_public(){
  request_bulk_privacy(0);
}

function request_bulk_private(){
  request_bulk_privacy(1);
}

function request_bulk_delete(){
  list_of_dives = [];

  $("#wizard_export_list input:checked").each(function(index, value) {
    list_of_dives.push(value.name);
  });

  if (list_of_dives.length == 0){
    alert(I18n.t(["js","wizard","You must select at least one dive to delete"]));
    return;
  }

  if (!confirm(I18n.t(["js","wizard","This will delete the %{count} selected dives. Are you sure ?"], {count: list_of_dives.length}))) return;

  $("#tab_bulklist_content").html('<img src="/img/transparent_loader.gif" style="margin-left: 40%; margin-top: 25% " alt="#">');
  $.ajax({
    url: "/api/delete_dives",
    data: ({
      listDives: list_of_dives,
      'authenticity_token': auth_token
    }),
    type: "POST",
    dataType: "json",
    error: function(data) {
      diveboard.alert(I18n.t(["js","wizard","A technical error happened while updating the dives."]), null, function(){
        document.location = "/"+G_owner_api.vanity_url+"/bulk?bulk=manager";
      });
    },
    success: function(data) {
      if (data.success)
        document.location = "/"+G_owner_api.vanity_url+"/bulk?bulk=manager";
      else
        diveboard.alert(I18n.t(["js","wizard","A technical error happened while updating the dives."]), null, function(){
          document.location = "/"+G_owner_api.vanity_url+"/bulk?bulk=manager";
        });
    }
  });
}

jQuery.download = function(url, data, method){
  //url and data options required
  if( url && data ){
    //data can be string of parameters or array/object
    //data = typeof data == 'string' ? data : jQuery.param(data);
    //split params into form inputs
    var inputs = '';
    jQuery.each(data.split('&'), function(){
      var pair = this.split('=');
      inputs+='<input type="hidden" name="'+ pair[0] +'" value="'+ escape(pair[1]) +'" />';
    });
    inputs+='<input type="hidden" name="authenticity_token" value="'+auth_token+'" />';
    //send request
    jQuery('<form action="'+ url +'" method="'+ (method||'post') +'">'+inputs+'</form>').appendTo('body').submit().remove();
  };
};

function request_bulk_print(){
  list_of_dives = [];

  $("#wizard_export_list input:checked").each(function(index, value) {
    list_of_dives.push(value.name);
  });

  if (list_of_dives.length == 0){
    alert(I18n.t(["js","wizard","You must select at least one dive to print"]));
    return;
  }


  $(".main_content_box").hide();
  $('#wizard_bulk_print_div').hide();
  $('#bulk_wizard_tab').show();
  $("#file_mask_light").show().css("background-color","rgba(0,0,0,0)");
  $.ajax({
    url: "/api/print_dives",
    data: ({
      listDives: list_of_dives,
      size: $("#bulk_print_format").val(),
      pictures: $("#bulk_print_pictures").val(),
      'authenticity_token': auth_token
    }),
    type: "POST",
    dataType: "json",
    success: function(data){
      if(data["success"] == true)
        diveboard.notify(I18n.t(["js","wizard","Success"]), I18n.t(["js","wizard","Generation of your logbook has <b>started</b>.<br/>In a few minutes, you'll get an email at '%{email}' to let you know it's ready for download."], {email: data.contact_email}));
      else
        diveboard.alert(I18n.t(["js","wizard","The generation of the PDF failed."]), data);

      $("#file_mask_light").hide().css("background-color","#000000");
      $(".main_content_box").show();
    },
    error: function(data) {
      diveboard.alert("The generation of the PDF failed.");
      $("#file_mask_light").hide().css("background-color","#000000");
      $(".main_content_box").show();
    }
  });
  $("#bulk_print_format").val("a5-2");
  $("#bulk_print_pictures").val("-1");
}

function request_bulk_trip(ev) {
  if (ev) ev.preventDefault();

  var requests_obj = [];

  $('#wizard_export_list input:checked').each(function(idx, elt){
    var params_obj = {
      id: parseInt(elt.name),
      dive: {
        trip_name: $('#wizard-trip').val() || null
      }
    };

    requests_obj.push({
      call: '/dive/update',
      method: 'post',
      params: params_obj
    });
  });

  request_bulk_ajax(requests_obj);
}

function request_bulk_number(ev) {
  if (ev) ev.preventDefault();

  var requests_obj = [];

  $('#wizard_bulk_numbering_data li').each(function(idx, elt){
    var params_obj = {
      id: parseInt($(elt).attr("name")),
      dive: {
        number: Number($(elt).find("input").val()) || null
      }
    };

    requests_obj.push({
      call: '/dive/update',
      method: 'post',
      params: params_obj
    });
  });

  request_bulk_ajax(requests_obj);
}


function request_bulk_water(ev) {
  if (ev) ev.preventDefault();

  var requests_obj = [];

  $('#wizard_export_list input:checked').each(function(idx, elt){
    var params_obj = {
      id: parseInt(elt.name),
      dive: {
        water: $('#water').val() || null
      }
    };

    requests_obj.push({
      call: '/dive/update',
      method: 'post',
      params: params_obj
    });
  });

  request_bulk_ajax(requests_obj);
}

function request_bulk_visibility(ev) {
  if (ev) ev.preventDefault();

  var requests_obj = [];

  $('#wizard_export_list input:checked').each(function(idx, elt){
    var params_obj = {
      id: parseInt(elt.name),
      dive: {
        visibility: $('#wizard-visibility').val() || null
      }
    };

    requests_obj.push({
      call: '/dive/update',
      method: 'post',
      params: params_obj
    });
  });

  request_bulk_ajax(requests_obj);
}

function request_bulk_altitude(ev) {
  if (ev) ev.preventDefault();

  var requests_obj = [];

  $('#wizard_export_list input:checked').each(function(idx, elt){
    var params_obj = {
      id: parseInt(elt.name),
      dive: {
        altitude: $("#altitude").val()?unit_distance_n(parseFloat($("#altitude").val()), true):null
      }
    };

    requests_obj.push({
      call: '/dive/update',
      method: 'post',
      params: params_obj
    });
  });

  request_bulk_ajax(requests_obj);
}


function request_bulk_shop(ev) {
  if (ev) ev.preventDefault();

  var data_to_send = {};

  data_to_send['guide'] = $("#guide").val();

  if ($("#wz_shop_found_id").val() == '' && $('#diveshop-name').attr('readonly')) {
    var diveshop = new Object();
    diveshop['name'] = $("#diveshop-name").val();
    diveshop['country'] = $("#diveshop-country").val();
    diveshop['town'] = $("#diveshop-town").val();
    diveshop['url'] = $("#diveshop-url").val();
    if (diveshop['name'] =="") diveshop['name'] = diveshop['url'];
    if (diveshop['name'] =="") diveshop = null;
    data_to_send['diveshop'] = diveshop;
  }

  data_to_send['shop_id'] = $("#wz_shop_found_id").val();
  if (!$("#wz_shop_found_name").is(":visible"))
    data_to_send['shop_id'] = '';

  data_to_send['request_shop_signature'] = $("#signing_shop_request").is(":checked");

  var requests_obj = [];

  $('#wizard_export_list input:checked').each(function(idx, elt){
    var params_obj = {
      id: parseInt(elt.name),
      dive: data_to_send
    };

    requests_obj.push({
      call: '/dive/update',
      method: 'post',
      params: params_obj
    });
  });

  request_bulk_ajax(requests_obj);
}

function request_bulk_buddy(ev) {
  if (ev) ev.preventDefault();

  var buddy_json = JSON.stringify(get_buddy_object());

  var requests_obj = [];

  $('#wizard_export_list input:checked').each(function(idx, elt){
    var params_obj = {
      id: parseInt(elt.name),
      dive: {
        buddies: buddy_json
      }
    };

    requests_obj.push({
      call: '/dive/update',
      method: 'post',
      params: params_obj
    });
  });

  request_bulk_ajax(requests_obj);
}


function request_bulk_location(ev) {
  if (ev) ev.preventDefault();

  if( wizard_spot_datacheck()==false ){
    diveboard.notify(I18n.t(["js","wizard","Spot parameters"]), I18n.t(["js","wizard","ERROR: Cannot Save. Please correct the fields highlighted in red"]));
  }

  if (!wizard_compare_spot_data() && !wizard_spot_datacheck())
    return;

  //first, save the spot if it changed
  //if returns false, then the user needs to answer some questions
  //about what to do with the spot, so let's wait for his answer
  if (!wizard_check_create_spot(request_bulk_location, false))
    return;

  //Empty the examples
  $('.example').val('');


  var requests_obj = [];

  $('#wizard_export_list input:checked').each(function(idx, elt){
    var params_obj = {
      id: parseInt(elt.name),
      dive: {
        spot_id: parseInt($("#spot-id").val())
      }
    };

    requests_obj.push({
      call: '/dive/update',
      method: 'post',
      params: params_obj
    });
  });

  request_bulk_ajax(requests_obj);

}

function request_bulk_gear(ev) {
  if (ev) ev.preventDefault();


  var user_gear = [];
  var dive_gear = [];
  $('.gear_wizard_table .data_gear').each(function(i, elt){
    var data = $(elt).data('diveboard_gear_wizard');
    data.featured = ($(elt).find('.featured:checked').length > 0);

    if ($(elt).find('.absent:checked').length == 0)
      if (data['class'] == 'UserGear')
        user_gear.push({
          'id': data['id'],
          'class': data['class'],
          'featured': data['featured']
        });
      else {
        var data_copy = $.extend({}, data);
        delete data_copy.id;
        dive_gear.push(data_copy);
      }
  });

  var requests_obj = [];

  $('#wizard_export_list input:checked').each(function(idx, elt){
    var params_obj = {
      id: parseInt(elt.name),
      dive: {
        user_gear: JSON.stringify(user_gear),
        dive_gear: JSON.stringify(dive_gear)
      }
    };

    requests_obj.push({
      call: '/dive/update',
      method: 'post',
      params: params_obj
    });
  });

  request_bulk_ajax(requests_obj);
}

function request_bulk_ajax(requests_obj) {
  diveboard.mask_file(true);
  list_of_dives = [];

  $("#wizard_export_list input:checked").each(function(index, value) {
    list_of_dives.push(value.name);
  });

  $.ajax({
    url: '/api/bulk_proxy',
    dataType: 'json',
    data: {
      requests: JSON.stringify(requests_obj)
    },
    type: "POST",
    success: function(data){
      if (console && console.log) console.log(data);
      if (data['success']) {
        //window.location.reload();
       diveboard.unmask_file();
       diveboard.notify(I18n.t(["js","wizard","Success"]), "<span style='color: green' class='symbol'>.</span> "+I18n.t(["js","wizard","Dives successfully updated"]), function(){
         window.location.replace("/"+G_owner_vanity_url+"/bulk?bulk=manager&selected_dives="+list_of_dives.toString());
       });
      } else {
        //diveboard.mask_file(true);
        diveboard.unmask_file();
        diveboard.alert(I18n.t(["js","wizard","A technical error occured during the update of dives."]), data, function() {
          window.location.replace("/"+G_owner_vanity_url+"/bulk?bulk=manager&selected_dives="+list_of_dives.toString());
        });
      }
    },
    error: function(data){
      if (console && console.log) console.log(data);
      diveboard.unmask_file();
      diveboard.alert(I18n.t(["js","wizard","A technical error occured during the update of dives."]), null, function() {
        //window.location.reload();
        window.location.replace("/"+G_owner_vanity_url+"/bulk?bulk=manager&selected_dives="+list_of_dives.toString());
      });
    }
  });
}

function magic_bulk_numbering(element){
  kiki = element;
  var dives = $.map($.makeArray($("#wizard_bulk_numbering_template li")).reverse(), function(val,i){ return $(val).attr("name"); });
  var offset = Number($("#wizard_bulk_numbering_data_ext").val())+1;
  var delta = 0;
  if (element){
    var target = element.target || element.srcElement;
    if (target && target.id == "wizard_bulk_numbering_div_magic")
      var rw = true;
    else
      var rw = false;
  }else
  var rw=false;


  $.each(dives, function(index, value){
    var l = $("#wizard_bulk_numbering_data").find("li[name='"+value+"']");
    if (l.length>0){
      console.log("processing item "+index);

      if (rw)
        $(l).find("input").val(Number(offset)+index + delta);
      else {
          delta = Number($(l).find("input").val()) - Number(offset)-index;
        }
      if (element && $(l)[0] == $(element)[0])
        {
          console.log("item "+index+"is the one");
          rw = true;
        }
    }
  });
}

function update_following_dives_numbering(ev){
  if(ev){
    ev.preventDefault();
    var l  = $(ev.target || ev.srcElement).parent();
    if ($(l).find("input").val() != "")
      magic_bulk_numbering(l);
  }
}



//<!-- ##############  PLUGIN DIVE COMPUTER ############### -->



function Plugin_ShowState(divname)
{
  $("#wizard_plugin_uploader div").hide();
  $("#"+divname).show();
}


function fp()
{
  return plugin();
  }

// Functions for plugin


//Actions to perform once the plugin is loaded
function pluginLoaded()
{
  if (!CheckPlugin())
  {
    setTimeout('pluginLoaded()', 200);
    return;
  }

  refresh_to(3000);

  try
  {
    if (!plugin_loaded) {//we need to "addEvent" only once otherwise it will submit data multiple times
      plugin_addEvent('progress',
      function(x) {
        try {
          $("#progressbar").progressbar({
            value: (x * 0.9)
          });
        } catch(e){}
      });

      plugin_addEvent('error', handlePluginError);

      plugin_addEvent('loaded',
      function(x) {
        //refresh();
        ga('send', '_trackEvent', 'Wizard', 'Upload complete', G_W_model);
        try {
          $("#progressbar").progressbar({
            value: 90
          });
        } catch(e){}
        //alert("Data loaded !");
        document.getElementById("xmlFormSend").value = x;
        var local_logs = plugin().logs;
        if (local_logs.indexOf('CRITICAL') >= 0 || local_logs.indexOf('ERROR') >= 0 || local_logs.indexOf('WARNING') >= 0)
          document.getElementById("logFormSend").value = local_logs;
        document.getElementById("verFormSend").value = plugin().version;
        document.getElementById("nbrFormSend").value = plugin().nbDivesRead;
        document.getElementById("nbtFormSend").value = plugin().nbDivesTotal;
        //document.getElementById("subFormSend").submit();
        $("#progressStatus").text(I18n.t(["js","wizard","Sending data to Diveboard..."]));
        wizard_plugin_submit_data();
      });
      plugin_loaded = true;
    }

    Plugin_ShowState("detectBox1");

    //handle timeouts when loading the plugin
    //todo : find a way to catch error/exceptions while loadting the plugin
    //setTimeout("if (!CheckPlugin()) handlePluginError('Plugin irresponsive')",20000);
  }
  catch (err) {
    handlePluginError(err);
  }
}


function handlePluginError(err){
  //Cancellation is not really an exception and is handled differently
  if (err.substr && err.substr(-22) == "Error code : Cancelled")
    return;

  ga('send', 'event', 'Wizard', 'Error', err);
  $("#wizard_plugin_error").html(err);
  if (autodetect_plugin_download())
    $("#wizard_plugin_error_download").show();
  else
    $("#wizard_plugin_error_download").hide();

  Plugin_ShowState("errorBox");

  //do not send logs for timeout or cancellation
  if (err.substr && err.substr(-20) == "Error code : Timeout")
    return;
  wizard_plugin_submit_logs();
}

var plugin_loaded = false;
//Actions to perform once the page is loaded
function wizard_computeragent_load(){
  $("#wizard_add_profile").hide();
  $(".manual_creation").hide();
  $("#wizard2_next").hide();
  $("#wizard_plugin_uploader").hide();
  $("#wizard_agent_download").show();

}
function wizard_computerplugin_load()
{
  $("#wizard_add_profile").hide();
  $(".manual_creation").hide();
  $("#wizard2_next").hide();
  $("#wizard_agent_download").hide();
  $("#wizard_plugin_uploader").show();

  //For the plugin after Novmber 2012, use the plugin's support
  try {
    var supported = plugin().support;
    if (supported) {
      supported.sort(function(a,b){if (a.label==b.label) return 0; else if (a.label > b.label) return 1; else return -1;})
      var select = $('#wizard_computer_select2 option').first().detach();
      $('#wizard_computer_select1, #wizard_computer_select2').html('');
      $('#wizard_computer_select1, #wizard_computer_select2').append(select);

      for (var i in supported){
        var computer = supported[i];
        var found = false;
        for (var k in G_uploader_list_favorites)
          if (G_uploader_list_favorites[k] == computer.label)
            found = true
        if (found)
          $('#wizard_computer_select1, #wizard_computer_select2').append('<option value="'+computer.key_code+'">'+computer.label+"</option>");
      }

      $('#wizard_computer_select1, #wizard_computer_select2').append('<option value="XXX">--------------------</option>');

      for (var i in supported){
        var computer = supported[i];
        var emulator = false;
        for (var k in G_uploader_list_emulators)
          if (G_uploader_list_emulators[k] == computer.label)
            emulator = true
        if (!emulator)
          $('#wizard_computer_select1, #wizard_computer_select2').append('<option value="'+computer.key_code+'">'+computer.label+"</option>");
      }

      $('#wizard_computer_select1, #wizard_computer_select2').append('<option value="XXX">--------------------</option>');

      for (var i in supported){
        var computer = supported[i];
        var found = false;
        for (var k in G_uploader_list_emulators)
          if (G_uploader_list_emulators[k] == computer.label)
            found = true
        if (found)
          $('#wizard_computer_select1, #wizard_computer_select2').append('<option value="'+computer.key_code+'">'+computer.label+"</option>");
      }
    }
  } catch(err){}

  try {
    //pre-set the computer if a cookie is set
    var ARRcookies=document.cookie.split(";");
    for (var i=0;i<ARRcookies.length;i++)
    {
      var key=ARRcookies[i].substr(0,ARRcookies[i].indexOf("="));
      var val=ARRcookies[i].substr(ARRcookies[i].indexOf("=")+1);
      key=key.replace(/^\s+|\s+$/g,"");
      if (key=="lastComputerUsed")
      {
        $("#wizard_computer_select1 option").each(function(idx, elt){ if (elt.text == val) $(elt).attr('selected', true);});
      }
    }
  } catch (err) {}

  try {
    //if(!navigator.mimeTypes["application/x-diveboard"].enabledPlugin)
    if (!CheckPlugin())
    {
      setTimeout('if (!CheckPlugin()) Plugin_ShowState("installBox")', 4000);
      return;
    }
  }
  catch (err) {
    handlePluginError(err);
  }
}

function CheckPlugin()
{
  var found=false;

  try
  {
    var PLUGIN = document.getElementById("plugin");
    if( PLUGIN.name == "DiveBoard Reader" || (PLUGIN.version && PLUGIN.logs)) found=true;
    //if (navigator.mimeTypes["application/x-diveboard"]) found = true;
  }
  catch (err) {
  }

  return(found);
}

function CheckBrowser()
{
  var s = navigator.userAgent;//alert(s);
  var a = s.indexOf("Apple");
  var c = s.indexOf("Chrome");
  var ie = s.indexOf("MSIE");

  if( c > 0 )//is there chrome
  {
    alert( "Chrome dont like functions with parameters.");
    return true;
  }

  if( ie > 0 )//is there chrome
  {
    alert( "Internet Explorer dont like NPAPI at all.");
    return true;
  }

  if( a > 0 )//is there chrome
  {
    alert( "Apple Safari dont like NPAPI at all.");
    return true;
  }

  return false;
}


function plugin_reset_port_list()
{
  try
  {
    $("#wizard_plugin_port").empty();

    var ports = plugin().allports();
    var p_count = 0;

    for (var key in ports)
    {
      var label;
      if (key != ports[key]) label = key.replace(/[^A-Za-z0-9]/g, "")+": "+ports[key];
      else label = ports[key];
      $("#wizard_plugin_port").append("<option value='"+key+"'>"+label+"</option>");
      p_count++;
    }
    if (p_count == 0) {
      for (var k = 0; k<25; k++)
        $("#wizard_plugin_port").append("<option value='\\\\.\\COM"+k+"'>COM "+k+"</option>");
    }
  }
  catch (err) {
    handlePluginError(err);
  }
}


function plugin_detect_and_extract()
{
  //if( CheckBrowser() ) return;

  try
  {
    if (!CheckPlugin())
    {
      Plugin_ShowState("installBox");
      //$("#plugin").hide();
      return;
    }

    ga('send', 'event', 'Wizard', 'Computer selected - detect', $("#wizard_computer_select1 option:selected").text());

    var driver = $("#wizard_computer_select1").val();
    var model = $("#wizard_computer_select1 option:selected").text();
    var port = plugin().detect(driver);

    //Did the plugin find automagically the port on which to run ?
    if (port == "")
    {
      //If not, then we need to ask the user to provide the port
      $("#wizard_computer_select2 option").each(function(index, val) { if (val.text == model) $("#wizard_computer_select2 option")[index].selected=true;} );
      Plugin_ShowState("detectBox2");
      plugin_reset_port_list();
      wizard_computer_show_instructions();
    }
    else
    {
      Plugin_Extract(port, driver, model);
    }
  }
  catch (err) {
    handlePluginError(err);
  }
}



function plugin_force_extract()
{
  try
  {
    ga('send', 'event', 'Wizard', 'Computer selected - force', $("#wizard_computer_select1 option:selected").text());
    var port = document.getElementById("wizard_plugin_port").value;
    var model = $("#wizard_computer_select2 option:selected").text();
    var computer = document.getElementById("wizard_computer_select2").value;

    Plugin_Extract(port, computer, model);
  }
  catch (err) {
    handlePluginError(err);
  }
}


function Plugin_Extract(port, computer, model)
{
  try
  {
    var exdate=new Date();
    exdate.setDate(exdate.getDate() + 365*5);
    document.cookie = "lastComputerUsed="+model+";path=/;expires="+exdate.toUTCString()+";domain="+$("meta[name='db-cookie-domain']").attr("content");
  } catch (err) {}

  $("#progressStatus").text(I18n.t(["js","wizard","Reading the profiles from your computer..."]));

  try
  {
    G_W_model = model;
    ga('send','event', 'Wizard', 'Start extract', model);
    var a = document.getElementById("output");
    a.value = "Extracting...";
    Plugin_ShowState("progressBox");
    $("#progressbar").show();
    try {
      $("#progressbar").progressbar({value: 1});
    } catch(e){}
    var res = plugin().extract(port, computer);
  }
  catch (err) {
    alert(err);
    handlePluginError(err);
  }
}


function refresh()
{
  refresh_to(-1);
}


function refresh_to(timeout)
{
  try
  {
    var status = plugin().status;
    //if (status.nbDivesRead > 0) document.getElementById("progressNumber").value = status.nbDivesRead;
    if (status.percent > 0)  $("#progressbar").progressbar({value: status.percent });
  }
  catch (err) {}
  if (timeout > 0) setTimeout("refresh_to("+timeout+");",timeout);
}



function cancelAll()
{
  $("#progressBox").hide();
  //todo really cancel what the plugin does
}

function wizard_plugin_submit_logs() {
  //this function has no success nor error handlers, but that's intended to be so
  if (plugin())
  {
    $.ajax({
      url: "/api/put_logs",
      data: {
        'authenticity_token': auth_token,
        data: plugin().logs,
        platform: navigator.platform,
        browser: navigator.appVersion,
        plugin: plugin().version,
        user_name: typeof G_owner_full_name=='string'?G_owner_full_name:'',
        user_email: typeof G_owner_email=='string'?G_owner_email:'',
        user_id: G_owner_id
      },
      type: "POST",
      dataType: "json"
    });
  }
}

function wizard_plugin_submit_data() {
  g_send_plugin_data_xhr = $.ajax({
    url: "/api/computerupload.json",
    data: {
      'authenticity_token': auth_token,
      xmlFormSend: $("#xmlFormSend").val(),
      logFormSend: $("#logFormSend").val(),
      verFormSend: $("#verFormSend").val(),
      nbrFormSend: $("#nbrFormSend").val(),
      nbtFormSend: $("#nbtFormSend").val(),
      computer_model: G_W_model,
      user_id: G_owner_id
    },
    type: "POST",
    dataType: "json",
    error: function(data) { diveboard.alert(I18n.t(["js","wizard","The profile could not be uploaded to Diveboard"])); },
    success: function(data) {
      if (data.success) {
        try {
          $( "#progressbar" ).progressbar({value: 100});
        } catch(e){}
        $("#wizard_plugin_uploader").hide();
        wizard_dive_all_summary = data["dive_summary"];
        if (data["nbdives"] == "1" && !wizard_bulk) {
            //only one dive - let's update the page
            $("#profile-updated").val("update");
            $("#profile-fileid").val(data["fileid"]);
            $("#profile-diveid").val(0);
            wizard_dive_selected_summary = wizard_dive_all_summary[0];
            show_profile_uploaded();
        } else {
            set_dive_picker(data);
        }
      } else {
        diveboard.alert(I18n.t(["js","wizard","The profile could not be uploaded to Diveboard"]), data);
      }
    }
  });
}
function wizard_plugin_cancel(){
  try {
    plugin().cancel();
  } catch (err) {}

  try {
    g_send_plugin_data_xhr.abort();
    g_send_plugin_data_xhr = null;
  } catch (err) {}

  $("#wizard_add_profile").show();
  $("#wizard_plugin_uploader").hide();
  $("#dive_list_selector").hide();
  $("#wizard_computer_instructions1").hide();
  $("#wizard_computer_instructions2").hide();
  $("#dive_list_selected").empty();

  if(!wizard_bulk){
    $(".manual_creation").show();
    $("#wizard2_next").show();
  }
  else{
    $(".manual_creation").hide();
  }

  wizard_plugin_retry();
}

function wizard_plugin_retry()
{
  if (!CheckPlugin())
  {
    //flushing and recreating the plugin object to force the browser to try and reload the plugin
    var objHTML = $("#pluginContainer").html();
    $("#pluginContainer").html("");
    $("#pluginContainer").html(objHTML);

    setTimeout('if (!CheckPlugin()) Plugin_ShowState("installBox")', 4000);
    Plugin_ShowState("introBox");
  }
  else
    Plugin_ShowState("detectBox1");
}

/*

*********   DATA CHECK FUNCTION   ***********

*/
function wizard_spot_datacheck() {
  //returns true or false
  var result = true;
  if ($("#spot-country").attr("shortname") == "" /*|| $("#spot-country").attr("shortname") == "blank"*/) {
      result = false;
      $("#spot-country").addClass("wizard_input_error");
  } else {
      $("#spot-country").removeClass("wizard_input_error");
  }

  if (isNaN(parseFloat($("#spot-lat").val())) || parseFloat($("#spot-lat").val()) > 90 || parseFloat($("#spot-lat").val()) < -90) {
      result = false;
      $("#spot-lat").addClass("wizard_input_error");
  } else {
      $("#spot-lat").removeClass("wizard_input_error");
  }

  if (isNaN(parseFloat($("#spot-long").val())) || parseFloat($("#spot-long").val()) > 180 || parseFloat($("#spot-long").val()) < -180) {
      result = false;
      $("#spot-long").addClass("wizard_input_error");
  } else {
      $("#spot-long").removeClass("wizard_input_error");
  }

  return result;
}

function renumber_tanks(){
  $(".scuba_tank").each(function(index){$($(this).find('span')[0]).text(index+1);
    if (index==0) $($(this).find('.starttime')[0]).hide(); else $($(this).find('.starttime')[0]).show();
  });
}

function update_n2_from_others(custom_airmix){
  if (custom_airmix.data('customised_n2'))
    return;
  var o2 = custom_airmix.find('.o2').val();
  var he = custom_airmix.find('.he').val();
  var n2 = 100-o2-he;
  custom_airmix.find('.n2').val(n2>0?n2:0);
}

function extract_tank_data(){
  var tank_data = new Array;
  $(".tank_container .scuba_tank").each(function(index, value){
    //extracts and normalized data to SI for storage... keeps data as float if there has been funky stuff and time as s
    var tank = new Object;
    tank["material"] = $(value).find(".material").val();
    if ($(value).find(".v_unit").val()=="L")
      tank["volume"] = $(value).find(".volume").val();
    else
      tank["volume"] = $(value).find(".volume").val()/100*12;
    tank["gas_type"]=$(value).find(".gas").val();
    tank["o2"]=$(value).find(".o2").val();
    tank["he"]=$(value).find(".he").val();
    tank["n2"]=$(value).find(".n2").val();
    if ($(value).find(".p_unit").val()=="bar"){
      tank["p_start"]=$(value).find(".p_start").val();
      tank["p_end"]=$(value).find(".p_end").val();
    }else{
      tank["p_start"]=$(value).find(".p_start").val()/14.5037738;
      tank["p_end"]=$(value).find(".p_end").val()/14.5037738;
    }
    tank["time"]=$(value).find(".time_m").val()*60;
    tank["order"] = index;
    tank["multitank"] = $(value).find(".multitank").val();
    tank["tank_id"] = $(value).find(".tank_id").val();
    tank_data.push(tank);
  });
  return tank_data;
}

function add_buddy(ev){
  if(ev)
    ev.preventDefault();

  var buddy_id = $(".edit_buddy_list li").length;

  if($('.buddy_manual').css("display") != "none"){
    if ($("#buddy-name").val() == "") {
      alert("Sorry, can't add an empty name");
      return;
    }

    var name = $("#buddy-name").val();
    var email = $("#buddy-email").val();
    var notify = $("#invite_buddy_by_email").prop('checked');
    var hash = MD5(email);
    $(".edit_buddy_list").append("<li class=\"buddy\"><img src='/img/no_picture.png' class='buddy_picker_list'/><span class='buddy_picker_list_span'>"+name+" "+I18n.t(["js","wizard","via email"])+" <a href='#' class='remove_buddy'>"+I18n.t(["js","wizard","Remove Buddy"])+"</a></span> </li>");
    $($(".buddy")[buddy_id]).prepend("<input type='hidden' name='"+name+"' email='"+email+"' notify='"+notify+"'/>");
    $.get("/api/user/checkgravatar?hash="+hash,function(data){
      //If user has a gravatar we can add his picture ; if it fails, we didn't really care
      if (data.success){
        $($(".buddy")[buddy_id]).find("img").attr("src",data.url);
        $($(".buddy")[buddy_id]).find("input").attr("picturl", data.url);
      }
    });
    $("#buddy-name").val("");
    $("#buddy-email").val("");

  }else if ($('.buddy_fb').css("display") != "none"){
    //add fb buddy
    if ($("#buddy-fb-name-hidden").attr("fb_id") == null || $("#buddy-fb-name-hidden").attr("fb_id") == "") {
      alert(I18n.t(["js","wizard","Sorry, you must choose a name from the list"]));
      return;
    }
    var fb_id = $("#buddy-fb-name-hidden").attr("fb_id");
    var name = $("#buddy-fb-name-hidden").attr("name");
    $("#buddy-fb-name-hidden").attr("fb_id", "");
    $("#buddy-fb-name-hidden").attr("name", "");
    $("#buddy-fb-name").val("");
    $(".edit_buddy_list").append("<li class=\"buddy\"><img src='https://graph.facebook.com/v2.0/"+fb_id+"/picture?type=square' class='buddy_picker_list'/><span class='buddy_picker_list_span'>"+name+" "+I18n.t(["js","wizard","via Facebook"])+" <a href='#' class='remove_buddy'>"+I18n.t(["js","wizard","Remove Buddy"])+"</a></span> </li>");
    $($(".buddy")[buddy_id]).prepend("<input type='hidden' name='"+name+"' fb_id='"+fb_id+"'/>");

  }else if ($('.buddy_db').css("display") != "none"){
    //add db buddy
    if ($("#buddy-db-name-hidden").attr("db_id") == null || $("#buddy-db-name-hidden").attr("db_id") == "") {
      alert(I18n.t(["js","wizard","Sorry, you must choose a name from the list"])); return;
    }
    var db_id= $("#buddy-db-name-hidden").attr("db_id");
    var name = $("#buddy-db-name-hidden").attr("name");
    var picture = $("#buddy-db-name-hidden").attr("picture");
    var notify = $("#invite_buddy_by_email").prop('checked');
    $("#buddy-db-name-hidden").attr("db_id", "");
    $("#buddy-db-name-hidden").attr("name", "");
    $("#buddy-db-name-hidden").attr("picture","");
    $("#buddy-db-name").val("");
    $(".edit_buddy_list").append("<li class=\"buddy\"><img src='"+picture+"' class='buddy_picker_list'/><span class='buddy_picker_list_span'>"+name+" "+I18n.t(["js","wizard","via Diveboard"])+" <a href='#' class='remove_buddy'>"+I18n.t(["js","wizard","Remove Buddy"])+"</a></span> </li>");
    $($(".buddy")[buddy_id]).prepend("<input type='hidden' name='"+name+"' db_id='"+db_id+"' notify='"+notify+"'/>");
  }
  if($(".edit_buddy_list li").length>0)
    $("#buddy_count").text($(".edit_buddy_list li").length);
  else
    $("#buddy_count").text("none");


}

function add_past_buddy(li){
  li = $(li);
  var src = li.find("img").attr('src');
  var name = li.text();
  var buddy_id = $(".edit_buddy_list li").length;

  $(".edit_buddy_list").append("<li class=\"buddy\"><img src='"+src+"' class='buddy_picker_list'/><span class='buddy_picker_list_span'>"+name+" <a href='#' class='remove_buddy'>"+I18n.t(["js","wizard","Remove Buddy"])+"</a></span> </li>");
  //ex_id for external users, db_id for users
  $($(".buddy")[buddy_id]).prepend("<input type='hidden' "+li.data('type')+"_id='"+li.data('id')+"'/>");
  $(li).hide();
}

function delete_buddy(b){
  var root = $(b).parent().parent();
  var ex_id = root.find("input").attr("ex_id");
  var db_id = root.find("input").attr("db_id");
  var type = ex_id?'ex':'db';
  var id = ex_id || db_id;
  $(".past_buddies li[data-type="+type+"][data-id="+id+"]").show();
  root.remove();
  $("#buddy_count").text($(".edit_buddy_list li").length);
}

function get_buddy_object() {
  var buddylist = new Array;
  $.each($(".edit_buddy_list li"), function(index, value){
    var buddy = new Object;
    buddy["name"] = $(value).find("input").attr("name");
    buddy["email"] = $(value).find("input").attr("email");
    buddy["picturl"] = $(value).find("input").attr("picturl");
    buddy["ex_id"] = $(value).find("input").attr("ex_id");
    buddy["fb_id"] = $(value).find("input").attr("fb_id");
    buddy["db_id"] = $(value).find("input").attr("db_id");
    buddy["notify"] = $(value).find("input").attr("notify") == "true";
    buddylist.push(buddy);
  });
  return buddylist;
}


function wizard_dive_datacheck() {
  var result = true;
  //Wizzard 2

  if($("#wizard-date").val() == "" || !isDate($("#wizard-date").val())){
    result = false;
    $("#wizard-date").addClass("wizard_input_error");
  } else {
    $("#wizard-date").removeClass("wizard_input_error");
  }

  if($("#wizard-time-in-hrs").val() == "" || !isInt($("#wizard-time-in-hrs").val() ) || $("#wizard-time-in-hrs").val() <0 || $("#wizard-time-in-hrs").val() > 23){
    result = false;
    $("#wizard-time-in-hrs").addClass("wizard_input_error");
  } else {
    $("#wizard-time-in-hrs").removeClass("wizard_input_error");
  }
  if($("#wizard-time-in-mins").val()=="" || !isInt($("#wizard-time-in-mins").val()) || $("#wizard-time-in-mins").val() < 0 || $("#wizard-time-in-mins").val() > 59){
    result = false;
    $("#wizard-time-in-mins").addClass("wizard_input_error");
  } else {
    $("#wizard-time-in-mins").removeClass("wizard_input_error");
  }
  if(!isInt($("#wizard-duration-mins").val() ) || $("#wizard-duration-mins").val() < 0){
    result = false;
    $("#wizard-duration-mins").addClass("wizard_input_error");
  } else {
    $("#wizard-duration-mins").removeClass("wizard_input_error");
  }
  if(isNaN(parseFloat($("#wizard-max-depth").val()) ) || parseFloat($("#wizard-max-depth").val()) < 0 || parseFloat($("#wizard-max-depth").val()) > 100000){
    result = false;
    $("#wizard-max-depth").addClass("wizard_input_error");
  } else {
    $("#wizard-max-depth").removeClass("wizard_input_error");
  }

  var total_stop_time = 0;
  $("#profile_table .wizard_input_error").removeClass("wizard_input_error");
  $("#profile_table .stop_def").each(function(i,e){
    var stop = $(e);
    var stop_depth = stop.find(".stop_depth").val();
    var stop_depth_unit = stop.find(".stop_depth_unit").val();
    var stop_time = stop.find(".stop_time").val();
    if (stop.attr('id') != 'stop_def_tmpl' && stop_depth != "" && stop_time != "") {
      if (!isFloat(stop_depth) || parseFloat(stop_depth) < 0 || parseFloat(stop_depth)>parseFloat($("#wizard-max-depth").val())){
        result = false;
        stop.find(".stop_depth").addClass("wizard_input_error");
        total_stop_time += parseInt(stop_time);
      }
      if (!isFloat(stop_time) || parseFloat(stop_time) < 0){
        result = false;
        stop.find(".stop_time").addClass("wizard_input_error");
      }
    }
  });

  if (isInt($("#wizard-duration-mins").val()) && $("#wizard-duration-mins").val() > 0) {
    if ($("#wizard-duration-mins").val() < total_stop_time) {
      result = false;
      $("#profile_table .stop_time").addClass("wizard_input_error");
    }
  }

  if($("#wizard-surface-temperature").val() != "" && isNaN(parseFloat($("#wizard-surface-temperature").val() ))){
    result = false;
    $("#wizard-surface-temperature").addClass("wizard_input_error");
  } else {
    $("#wizard-surface-temperature").removeClass("wizard_input_error");
  }
  if($("#wizard-bottom-temperature").val() != "" && isNaN(parseFloat($("#wizard-bottom-temperature").val() ))){
    result = false;
    $("#wizard-bottom-temperature").addClass("wizard_input_error");
  } else {
    $("#wizard-bottom-temperature").removeClass("wizard_input_error");
  }


  if (!result) {diveboard.notify(I18n.t(["js","wizard","Cannot save data"]),I18n.t(["js","wizard","Basic data are missing on the OVERVIEW pane.<br/>Please check the fields highlighted in red on the OVERVIEW pane before proceeding."])); return false;}

  //WIZARD STEP 3




  //FINISH
  return result;
}

function isInt(text){
  if (text == "") return false;
  if( !isNaN(Number(text)) && parseInt(Number(text)) == Number(text) ) return true; else return false;
}

function isFloat(text){
  if (text == "") return false;
  if( !isNaN(Number(text)) && parseFloat(Number(text)) == Number(text) ) return true; else return false;
}

function isDate(stringDate)
{
  var e = stringDate.match(/^([0-9][0-9][0-9][0-9])-([0-9]?[0-9])-([0-9]?[0-9])$/);
  if (!e) return(false);
  var y = parseInt(e[1],10);
  var m = parseInt(e[2],10);
  var d = parseInt(e[3],10);
  var date = new Date(y,m-1,d);
  var convertedDate = ""+date.getFullYear() + (date.getMonth()+1) + date.getDate();
  var givenDate = "" + y + m + d;
  return ( givenDate == convertedDate);
}


//FACEBOOK INTEGRATION
var fb_response;
function check_fb_post_to_wall_perms(){
  //this is for the post_to_wall button
  // we need to check that we have a workign token for that don't'cha'now!
  return;

  /*if ($("#fb_post_button").attr("checked")==false) {
    //we just clicked the button, so it's now false - right ? :)
    $("#fb_post_button").attr("checked", false);
    return;
  }
  if(G_user_fb_perms_post_to_wall){
    $("#fb_post_button").attr("checked", true);}
  else{
    $("#fb_post_button").attr("checked", false);
    FB.login(function(response) {
      fb_response = response ;
      if (response.perms != undefined && response.perms.match(/publish\_stream/)!=null) {
      G_user_fbtoken = FB.getAuthResponse().accessToken;
      $("#fb_post_button").attr("checked", true);
      G_user_fb_perms_post_to_wall = true;
      } else {
        // user cancelled login
      $("#fb_post_button").attr("checked", false);
      }
    }, {scope:'email,publish_stream'});
  }*/
}


//////////////////
//////////////////
// PRINT DIVES status update
/////////////////
function createRequestObject() {
  var ro;
  if (window.XMLHttpRequest) {
    ro = new XMLHttpRequest();
  } else {
    ro = new ActiveXObject("Microsoft.XMLHTTP");
  }
  if (!ro)
    debug("Couldn't start XMLHttpRequest object");
  return ro;
}
var prevDataLength = 0;
var nextLine = 0;
function startProcess(dataUrl) {
  prevDataLength = 0;
  nextLine = 0;
  http = createRequestObject();
  http.open('get', dataUrl);
  http.onreadystatechange = handleResponse;
  http.send(null);

  pollTimer = setInterval(handleResponse, 1000);
}
function handleResponse() {
  if (http.readyState != 4 && http.readyState != 3)
    return;
  if (http.readyState == 3 && http.status != 200)
    return;
  if (http.readyState == 4 && http.status != 200) {
    clearInterval(pollTimer);
    inProgress = false;
  }
  // In konqueror http.responseText is sometimes null here...
  if (http.responseText === null)
    return;

  while (prevDataLength != http.responseText.length) {
    if (http.readyState == 4  && prevDataLength == http.responseText.length)
      break;
    prevDataLength = http.responseText.length;
    var response = http.responseText.substring(nextLine);
    var lines = response.split('\n');
    nextLine = nextLine + response.lastIndexOf('\n') + 1;
    if (response[response.length-1] != '\n')
      lines.pop();
    answer = "";
    for (var i = 0; i < lines.length; i++) {
      answer += lines[i]+"\n"
    }
  alert(answer);
  }

  if (http.readyState == 4 && prevDataLength == http.responseText.length)
    clearInterval(pollTimer);

  inProgress = false;
}


(function($) {
$.fn.getHiddenDimensions = function(includeMargin) {
  var $item = this,
      props = { position: 'absolute', visibility: 'hidden', display: 'block' },
      dim = { width:0, height:0, innerWidth: 0, innerHeight: 0,outerWidth: 0,outerHeight: 0 },
      $hiddenParents = $item.parents().andSelf().not(':visible'),
      includeMargin = (includeMargin == null)? false : includeMargin;

  var oldProps = [];
  $hiddenParents.each(function() {
    var old = {};

    for ( var name in props ) {
      old[ name ] = this.style[ name ];
      this.style[ name ] = props[ name ];
    }

    oldProps.push(old);
  });

  dim.width = $item.width();
  dim.outerWidth = $item.outerWidth(includeMargin);
  dim.innerWidth = $item.innerWidth();
  dim.height = $item.height();
  dim.innerHeight = $item.innerHeight();
  dim.outerHeight = $item.outerHeight(includeMargin);

  $hiddenParents.each(function(i) {
    var old = oldProps[i];
    for ( var name in props ) {
      this.style[ name ] = old[ name ];
    }
  });

  return dim;
}
}(jQuery));


var MD5 = function (string) {

  function RotateLeft(lValue, iShiftBits) {
    return (lValue<<iShiftBits) | (lValue>>>(32-iShiftBits));
  }

  function AddUnsigned(lX,lY) {
    var lX4,lY4,lX8,lY8,lResult;
    lX8 = (lX & 0x80000000);
    lY8 = (lY & 0x80000000);
    lX4 = (lX & 0x40000000);
    lY4 = (lY & 0x40000000);
    lResult = (lX & 0x3FFFFFFF)+(lY & 0x3FFFFFFF);
    if (lX4 & lY4) {
      return (lResult ^ 0x80000000 ^ lX8 ^ lY8);
    }
    if (lX4 | lY4) {
      if (lResult & 0x40000000) {
        return (lResult ^ 0xC0000000 ^ lX8 ^ lY8);
      } else {
        return (lResult ^ 0x40000000 ^ lX8 ^ lY8);
      }
    } else {
      return (lResult ^ lX8 ^ lY8);
    }
  }

  function F(x,y,z) { return (x & y) | ((~x) & z); }
  function G(x,y,z) { return (x & z) | (y & (~z)); }
  function H(x,y,z) { return (x ^ y ^ z); }
  function I(x,y,z) { return (y ^ (x | (~z))); }

  function FF(a,b,c,d,x,s,ac) {
    a = AddUnsigned(a, AddUnsigned(AddUnsigned(F(b, c, d), x), ac));
    return AddUnsigned(RotateLeft(a, s), b);
  };

  function GG(a,b,c,d,x,s,ac) {
    a = AddUnsigned(a, AddUnsigned(AddUnsigned(G(b, c, d), x), ac));
    return AddUnsigned(RotateLeft(a, s), b);
  };

  function HH(a,b,c,d,x,s,ac) {
    a = AddUnsigned(a, AddUnsigned(AddUnsigned(H(b, c, d), x), ac));
    return AddUnsigned(RotateLeft(a, s), b);
  };

  function II(a,b,c,d,x,s,ac) {
    a = AddUnsigned(a, AddUnsigned(AddUnsigned(I(b, c, d), x), ac));
    return AddUnsigned(RotateLeft(a, s), b);
  };

  function ConvertToWordArray(string) {
    var lWordCount;
    var lMessageLength = string.length;
    var lNumberOfWords_temp1=lMessageLength + 8;
    var lNumberOfWords_temp2=(lNumberOfWords_temp1-(lNumberOfWords_temp1 % 64))/64;
    var lNumberOfWords = (lNumberOfWords_temp2+1)*16;
    var lWordArray=Array(lNumberOfWords-1);
    var lBytePosition = 0;
    var lByteCount = 0;
    while ( lByteCount < lMessageLength ) {
      lWordCount = (lByteCount-(lByteCount % 4))/4;
      lBytePosition = (lByteCount % 4)*8;
      lWordArray[lWordCount] = (lWordArray[lWordCount] | (string.charCodeAt(lByteCount)<<lBytePosition));
      lByteCount++;
    }
    lWordCount = (lByteCount-(lByteCount % 4))/4;
    lBytePosition = (lByteCount % 4)*8;
    lWordArray[lWordCount] = lWordArray[lWordCount] | (0x80<<lBytePosition);
    lWordArray[lNumberOfWords-2] = lMessageLength<<3;
    lWordArray[lNumberOfWords-1] = lMessageLength>>>29;
    return lWordArray;
  };

  function WordToHex(lValue) {
    var WordToHexValue="",WordToHexValue_temp="",lByte,lCount;
    for (lCount = 0;lCount<=3;lCount++) {
      lByte = (lValue>>>(lCount*8)) & 255;
      WordToHexValue_temp = "0" + lByte.toString(16);
      WordToHexValue = WordToHexValue + WordToHexValue_temp.substr(WordToHexValue_temp.length-2,2);
    }
    return WordToHexValue;
  };

  function Utf8Encode(string) {
    string = string.replace(/\r\n/g,"\n");
    var utftext = "";

    for (var n = 0; n < string.length; n++) {

      var c = string.charCodeAt(n);

      if (c < 128) {
        utftext += String.fromCharCode(c);
      }
      else if((c > 127) && (c < 2048)) {
        utftext += String.fromCharCode((c >> 6) | 192);
        utftext += String.fromCharCode((c & 63) | 128);
      }
      else {
        utftext += String.fromCharCode((c >> 12) | 224);
        utftext += String.fromCharCode(((c >> 6) & 63) | 128);
        utftext += String.fromCharCode((c & 63) | 128);
      }

    }

    return utftext;
  };

  var x=Array();
  var k,AA,BB,CC,DD,a,b,c,d;
  var S11=7, S12=12, S13=17, S14=22;
  var S21=5, S22=9 , S23=14, S24=20;
  var S31=4, S32=11, S33=16, S34=23;
  var S41=6, S42=10, S43=15, S44=21;

  string = Utf8Encode(string);

  x = ConvertToWordArray(string);

  a = 0x67452301; b = 0xEFCDAB89; c = 0x98BADCFE; d = 0x10325476;

  for (k=0;k<x.length;k+=16) {
    AA=a; BB=b; CC=c; DD=d;
    a=FF(a,b,c,d,x[k+0], S11,0xD76AA478);
    d=FF(d,a,b,c,x[k+1], S12,0xE8C7B756);
    c=FF(c,d,a,b,x[k+2], S13,0x242070DB);
    b=FF(b,c,d,a,x[k+3], S14,0xC1BDCEEE);
    a=FF(a,b,c,d,x[k+4], S11,0xF57C0FAF);
    d=FF(d,a,b,c,x[k+5], S12,0x4787C62A);
    c=FF(c,d,a,b,x[k+6], S13,0xA8304613);
    b=FF(b,c,d,a,x[k+7], S14,0xFD469501);
    a=FF(a,b,c,d,x[k+8], S11,0x698098D8);
    d=FF(d,a,b,c,x[k+9], S12,0x8B44F7AF);
    c=FF(c,d,a,b,x[k+10],S13,0xFFFF5BB1);
    b=FF(b,c,d,a,x[k+11],S14,0x895CD7BE);
    a=FF(a,b,c,d,x[k+12],S11,0x6B901122);
    d=FF(d,a,b,c,x[k+13],S12,0xFD987193);
    c=FF(c,d,a,b,x[k+14],S13,0xA679438E);
    b=FF(b,c,d,a,x[k+15],S14,0x49B40821);
    a=GG(a,b,c,d,x[k+1], S21,0xF61E2562);
    d=GG(d,a,b,c,x[k+6], S22,0xC040B340);
    c=GG(c,d,a,b,x[k+11],S23,0x265E5A51);
    b=GG(b,c,d,a,x[k+0], S24,0xE9B6C7AA);
    a=GG(a,b,c,d,x[k+5], S21,0xD62F105D);
    d=GG(d,a,b,c,x[k+10],S22,0x2441453);
    c=GG(c,d,a,b,x[k+15],S23,0xD8A1E681);
    b=GG(b,c,d,a,x[k+4], S24,0xE7D3FBC8);
    a=GG(a,b,c,d,x[k+9], S21,0x21E1CDE6);
    d=GG(d,a,b,c,x[k+14],S22,0xC33707D6);
    c=GG(c,d,a,b,x[k+3], S23,0xF4D50D87);
    b=GG(b,c,d,a,x[k+8], S24,0x455A14ED);
    a=GG(a,b,c,d,x[k+13],S21,0xA9E3E905);
    d=GG(d,a,b,c,x[k+2], S22,0xFCEFA3F8);
    c=GG(c,d,a,b,x[k+7], S23,0x676F02D9);
    b=GG(b,c,d,a,x[k+12],S24,0x8D2A4C8A);
    a=HH(a,b,c,d,x[k+5], S31,0xFFFA3942);
    d=HH(d,a,b,c,x[k+8], S32,0x8771F681);
    c=HH(c,d,a,b,x[k+11],S33,0x6D9D6122);
    b=HH(b,c,d,a,x[k+14],S34,0xFDE5380C);
    a=HH(a,b,c,d,x[k+1], S31,0xA4BEEA44);
    d=HH(d,a,b,c,x[k+4], S32,0x4BDECFA9);
    c=HH(c,d,a,b,x[k+7], S33,0xF6BB4B60);
    b=HH(b,c,d,a,x[k+10],S34,0xBEBFBC70);
    a=HH(a,b,c,d,x[k+13],S31,0x289B7EC6);
    d=HH(d,a,b,c,x[k+0], S32,0xEAA127FA);
    c=HH(c,d,a,b,x[k+3], S33,0xD4EF3085);
    b=HH(b,c,d,a,x[k+6], S34,0x4881D05);
    a=HH(a,b,c,d,x[k+9], S31,0xD9D4D039);
    d=HH(d,a,b,c,x[k+12],S32,0xE6DB99E5);
    c=HH(c,d,a,b,x[k+15],S33,0x1FA27CF8);
    b=HH(b,c,d,a,x[k+2], S34,0xC4AC5665);
    a=II(a,b,c,d,x[k+0], S41,0xF4292244);
    d=II(d,a,b,c,x[k+7], S42,0x432AFF97);
    c=II(c,d,a,b,x[k+14],S43,0xAB9423A7);
    b=II(b,c,d,a,x[k+5], S44,0xFC93A039);
    a=II(a,b,c,d,x[k+12],S41,0x655B59C3);
    d=II(d,a,b,c,x[k+3], S42,0x8F0CCC92);
    c=II(c,d,a,b,x[k+10],S43,0xFFEFF47D);
    b=II(b,c,d,a,x[k+1], S44,0x85845DD1);
    a=II(a,b,c,d,x[k+8], S41,0x6FA87E4F);
    d=II(d,a,b,c,x[k+15],S42,0xFE2CE6E0);
    c=II(c,d,a,b,x[k+6], S43,0xA3014314);
    b=II(b,c,d,a,x[k+13],S44,0x4E0811A1);
    a=II(a,b,c,d,x[k+4], S41,0xF7537E82);
    d=II(d,a,b,c,x[k+11],S42,0xBD3AF235);
    c=II(c,d,a,b,x[k+2], S43,0x2AD7D2BB);
    b=II(b,c,d,a,x[k+9], S44,0xEB86D391);
    a=AddUnsigned(a,AA);
    b=AddUnsigned(b,BB);
    c=AddUnsigned(c,CC);
    d=AddUnsigned(d,DD);
  }

  var temp = WordToHex(a)+WordToHex(b)+WordToHex(c)+WordToHex(d);

  return temp.toLowerCase();
}



///////////////////////////
//
// GEAR
//
///////////////////////////

function add_new_gear(ev)
{
  if (ev) ev.preventDefault();

  //Check validity of new gear parameters
  if ($('#add_gear_category').val() == '')
  {
    alert(I18n.t(["js","wizard","You must select a type for this piece of gear"]));
    return;
  }

  //Empty the examples
  $('.example').val('');

  //Add the new gear
  var data = {
    'class': 'DiveGear',
    'category': $('#add_gear_category').val(),
    'category_name': $('#add_gear_category option:checked').text(),
    'manufacturer': $('#add_gear_manufacturer').val(),
    'featured': true,
    'model': $('#add_gear_model').val()
  };
  var item = add_gear(data, $(".gear_wizard_table"));
  item.append( '<td><a href="#" class="add_own_gear">'+I18n.t(["js","wizard","I own it"])+'</a></td>');

  $('#add_gear_category').val('');
  $('#add_gear_manufacturer').val('');
  $('#add_gear_manufacturer').blur();
  $('#add_gear_model').val('');
  $('#add_gear_model').blur();
  $('.example').blur();
}

var add_gear_tmp_id = 0;
function add_gear(data, container)
{
  var tmp_id = add_gear_tmp_id++;
  var item = $('<tr class="data_gear gear_wizard_line"></tr>');

  var featured_checked = '';
  var private_checked  = '';
  var absent_checked   = '';
  if (data.featured == true)  featured_checked = 'checked';
  else if (data.featured == false) private_checked  = 'checked';
  else if (data.featured == null)  absent_checked   = 'checked';

  item.append($('<td/>').text(data.category_name || data.category));
  item.append($('<td/>').text(data.manufacturer));
  item.append($('<td/>').text(data.model));
  item.append($('<td/>').append("<input type=radio name='gear_tmp_"+tmp_id+"' "+featured_checked+" value='featured' class='featured'/>"));
  item.append($('<td/>').append("<input type=radio name='gear_tmp_"+tmp_id+"' "+private_checked +" value='private'  class='private'/>"));
  item.append($('<td/>').append("<input type=radio name='gear_tmp_"+tmp_id+"' "+absent_checked  +" value='absent'   class='absent'/>"));

  item.data('diveboard_gear_wizard', data);
  container.append(item);
  container.show();
  return(item);
}

var G_own_new_gear_xhr = null;
function own_new_gear(ev)
{
  if (ev) ev.preventDefault();

  if (G_own_new_gear_xhr) {
    return;
  }

  var elt=this;
  $(elt).hide();
  $(elt).parent().append('<img class="gearloading" src="/img/indicator.gif">');

  var data = $(elt).closest('.data_gear').data('diveboard_gear_wizard');

  var send_data = G_wizard_user_gear;
  send_data.push(data);

  G_own_new_gear_xhr = $.ajax({
    url: '/api/user/gear',
    dataType: 'json',
    data: {
            gear: JSON.stringify(send_data)
          },
    type: "POST",
    success: function(answer){
      G_own_new_gear_xhr = null;
      if (answer['success']) {
        G_wizard_user_gear = answer['user_gear'];

        //update the data of the new gear added
        var last_gear = null;
        $.each(G_wizard_user_gear, function(i,e){ if (last_gear == null || e.id > last_gear.id) {last_gear = e;} });
        if (last_gear)
          $(elt).closest('.data_gear').data('diveboard_gear_wizard', last_gear);
      }
      else {
        diveboard.alert(I18n.t(["js","wizard","A technical error happened while saving your gear."]), answer);
      }
    },
    error: function(answer) {
      G_own_new_gear_xhr = null;
      $(elt).show();
      diveboard.alert(I18n.t(["js","wizard","A technical error happened while saving your gear."]));
    },
    complete: function(data) {
      $(elt).parent().find('.gearloading').detach();
      G_own_new_gear_xhr = null;
    }
  });
}





function dan_form_to_hash(root)
{
  var h = {
    version: 1,
    encrypted: false,
    diver: {},
    dive: {},
    sent: false,
    previous: null
  };

  $(root).find(".dan_form_diver .dan_field").each(function(idx, elt) {
    h['diver'][ $(elt).attr('name') ] = $(elt).val() || null;
  });
  $(root).find(".dan_form_dive .dan_field").each(function(idx, elt) {
    h['dive'][ $(elt).attr('name') ] = $(elt).val() || null;
  });

  $(root).find(".dan_form_diver .dan_combo_field").each(function(idx, elt) {
    var name = $(elt).attr('name')
    if (!h['diver'][ name ])
      h['diver'][ name ] = [];
    h['diver'][name].push( $(elt).val()||null );
  });
  $(root).find(".dan_form_dive dan_combo_field").each(function(idx, elt) {
    var name = $(elt).attr('name')
    if (!h['dive'][ name ])
      h['dive'][ name ] = [];
    h['dive'][name].push( $(elt).val()||null );
  });


  //Data coming from other tabs

  //Gas
  //TODO? find the depth
  var bottom_gas = $('.tank_container .scuba_tank').first();
  if ( $('.tank_container .scuba_tank').length > 0 )
    h['dive']['bottom_gas'] = gas_to_dan_code($('.tank_container .scuba_tank').first());
  else
    h['dive']['bottom_gas'] = null;
  h['dive']['gases_number'] = $('.tank_container .scuba_tank').length;
  h['dive']['gases'] = [];
  $('.tank_container .scuba_tank').sort(function(a,b){return($(a).find('#time_m').val()>$(b).find('#time_m').val());}).each(function(i,g){
    if (i>0)
      h['dive']['gases'][i-1] += '<><'+ $(g).find('#time_m').val() + '>';
    h['dive']['gases'][i] = '<'+gas_to_dan_code(g) +'><><'+ $(g).find('#time_m').val()+'>';
  });
  h['dive']['gases'][ h['dive']['gases'].length-1 ] += '<><'+$("#wizard-duration-mins").val()+'>';

  //Visibility
  var visi = $('#wizard-visibility').val();
  if (visi == 'bad')
    h['dive']['visibility'] = 5;
  else if (visi == 'average')
    h['dive']['visibility'] = 10;
  else if (visi == 'good')
    h['dive']['visibility'] = 25;
  else if (visi == 'excellent')
    h['dive']['visibility'] = 50;
  else
    h['dive']['visibility'] = null;


  //Dress
  var dress = $.makeArray($('.tab_gear .data_gear').map(function(i,e){
    var category = $(e).data('diveboard_gear_wizard').category;
    if ( category == 'Dive skin') return(1);
    if ( category == 'Wet suit') return(2);
    if ( category == 'Dry suit') return(3);
    if ( category == 'Hot water suit') return(4);
  }));

  if (dress.length > 0)
    h['dive']['dress'] = dress[0];
  else
    h['dive']['dress'] = 5;

  //Apparatus
  var apparatus = $.makeArray($('.tab_gear .data_gear').map(function(i,e){
    var category = $(e).data('diveboard_gear_wizard').category;
    if ( category == 'Rebreather') return(2);
  }));
  if (apparatus.length > 0)
    h['dive']['apparatus'] = apparatus[0];
  else
    h['dive']['apparatus'] = 1; //Default is SCUBA

  //Current
  var current = $("#wizard-current").val();
  if (current == 'none')
    h['dive']['current'] = 0;
  else if (current == 'light')
    h['dive']['current'] = 1;
  else if (current == 'medium')
    h['dive']['current'] = 2;
  else if (current == 'strong')
    h['dive']['current'] = 3;
  else if (current == 'extreme')
    h['dive']['current'] = 5;
  else
    h['dive']['current'] = null;

  return(h);
}

function hash_to_dan_form(h, root)
{
  $(root).find(".dan_form_diver .dan_field").each(function(idx, elt) {
    $(elt).val( h['diver'] && h['diver'][ $(elt).attr('name') ]);
  });
  $(root).find(".dan_form_dive .dan_field").each(function(idx, elt) {
    $(elt).val( h['dive'] && h['dive'][ $(elt).attr('name') ]);
  });

  var combo_next = {};
  $(root).find(".dan_form_diver .dan_combo_field").each(function(idx, elt) {
    var name = $(elt).attr('name')
    if (!combo_next[name])
      combo_next[name] = 0;
    $(elt).val( h['diver'] && h['diver'][name][combo_next[name]] );
    combo_next[name]++;
  });
  combo_next = {};
  $(root).find(".dan_form_dive .dan_combo_field").each(function(idx, elt) {
    var name = $(elt).attr('name')
    if (!combo_next[name])
      combo_next[name] = 0;
    $(elt).val( h['dive'] && h['dive'][name][combo_next[name]] );
    combo_next[name]++;
  });

  $('.dan_field[name="hyperbar"]').attr('disabled',false).trigger('change');
  $('.dan_field[name="altitude_exposure"]').attr('disabled',false).trigger('change');
}

function dan_form_check_complete(root, show_remaining)
{
  var incomplete=0;

  // Check all the fields on the DAN export tab
  $(root).find('.dan_noempty').each(function(idx, elt){
    if (!$(elt).val()) {
      if (show_remaining) {
        $(elt).addClass('wizard_input_error');
      }
      incomplete++;
    } else {
      if (show_remaining)
        $(elt).removeClass('wizard_input_error');
    }
  });

  return(incomplete);
}

function dan_data_check_complete()
{
  var missing = [];

  //Tank
  if ( $('.tank_container .scuba_tank').length == 0)
    missing.push('gases');

  if ( $("#wizard-duration-mins").val() == '' )
    missing.push('duration');

  //suit
  var dress = $.makeArray($('.tab_gear .data_gear').map(function(i,e){
    var category = $(e).data('diveboard_gear_wizard').category;
    if ( category == 'Dive skin') return(1);
    if ( category == 'Wet suit') return(2);
    if ( category == 'Dry suit') return(3);
    if ( category == 'Hot water suit') return(4);
  }));

  if (dress.length == 0)
    missing.push('dress');

  return(missing);
}

function encrypt_dan_hash(data, pwd)
{
  if (data['encrypted']) return(data);

  data['encrypted'] = true;
  return(data);
}

function decrypt_dan_hash(data, pwd)
{
  if (!data['encrypted']) return(data);

  data['encrypted'] = false;
  return(data);
}

function check_dan_form_status(current_stored, previous_sent, show_remaining)
{
  var root = $(".dan_form");

  $('.dan_form_status p, .dan_not_complete').hide();
  $('.dan_field, .dan_combo_field').attr('disabled', false);

  if (!current_stored && previous_sent) {
    $('.dan_sent').show();
    $('.dan_field, .dan_combo_field').attr('disabled', true);
  }
  else {
    if (current_stored && previous_sent) {
      $('.dan_updating').show();
    } else {
      $('.dan_updating').hide();
    }

    var incomplete_1 = dan_form_check_complete(root, show_remaining);
    var incomplete_2 = dan_data_check_complete(root, show_remaining);

    var dan_percent = Math.round( 100 * (1.0 - ( 0.0 + incomplete_1 + incomplete_2.length) / ($('.dan_not_complete_tabs_item').length + $('.dan_noempty').length)) );
    $( "#dan_progress_bar" ).progressbar({value: dan_percent});
    $('#dan_complete_percent').text( dan_percent );

    if (incomplete_1 > 0) {
      $('.dan_not_complete_form').show();
      var list_missing = $.makeArray($('.dan_noempty').map(function(i,e){if ($(e).val() == '') return e;}).closest('li').find('.dan_question').map(function(i,e){return($(e).text());}))
      if (incomplete_1 > 3) {
        list_missing = list_missing.slice(0,3);
        list_missing.push('...');
      }
      $('#dan_complete_missing').text( list_missing.join(', ') );
    } else {
      $('.dan_not_complete_form').hide();
    }

    if (incomplete_2.length > 0) {
      $(".dan_not_complete_tabs_item").hide();
      $.each(incomplete_2, function(i,e){
        if (e == 'dress')
          $(".dan_not_complete_tabs_dress").show();
        if (e == 'gases')
          $(".dan_not_complete_tabs_gases").show();
        if (e == 'duration')
          $(".dan_not_complete_tabs_duration").show();
      });
      $(".dan_not_complete_tabs").show();
    } else {
      $(".dan_not_complete_tabs").hide();
    }


    $('.dan_complete').show();
    $('.dan_complete_hero').show();
    if (incomplete_1 > 0) {
      $('.dan_complete').hide();
      $('.dan_complete_hero').hide();
      $('.dan_not_complete').show();
    }
    if (incomplete_2.length > 0) {
      $('.dan_complete').hide();
      $('.dan_complete_hero').hide();
      $('.dan_not_complete').show();
      $('.dan_not_complete_tabs').show();
    }
    $('.dan_hero').each(function(idx, elt) {
      if (!$(elt).val())
        $('.dan_complete_hero').hide();
    });
  }
}

function gas_to_dan_code(tank_elt){
  var gas_val = $(tank_elt).find('.gas').val();
  if (gas_val == 'air')
    return('1');

  if (gas_val.substr(0,4) == 'EANx')
    return('2.'+gas_val.substr(4));

  if (gas_val == 'custom') {
    var o2 = format_integer( $(tank_elt).find('.o2').val(), 2) + '0';
    var n2 = format_integer( $(tank_elt).find('.n2').val(), 2) + '0';
    var he = format_integer( $(tank_elt).find('.he').val(), 2) + '0';

    //Nitrox
    if (he == 000)
      return('2.'+o2);

    //Heliox
    if (n2 == 000)
      return('4.'+o2);

    //Trimix
    return('6.'+o2+n2);
  }
}

function format_integer(val, before){
  if (!val) val = 0;
  var s = '';
  var e = Math.log(Math.abs(val))/Math.log(10);
  if (Math.abs(val) < 1) e = 1;
  for (var i = Math.floor(e)+1; i< before; i++)
    s += '0';
  s+= Math.floor(val);
  return(s);
}





var Base64 = {

  // private property
  _keyStr : "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",

  // public method for encoding
  encode : function (input) {
    var output = "";
    var chr1, chr2, chr3, enc1, enc2, enc3, enc4;
    var i = 0;

    input = Base64._utf8_encode(input);

    while (i < input.length) {

      chr1 = input.charCodeAt(i++);
      chr2 = input.charCodeAt(i++);
      chr3 = input.charCodeAt(i++);

      enc1 = chr1 >> 2;
      enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
      enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
      enc4 = chr3 & 63;

      if (isNaN(chr2)) {
        enc3 = enc4 = 64;
      } else if (isNaN(chr3)) {
        enc4 = 64;
      }

      output = output +
        this._keyStr.charAt(enc1) + this._keyStr.charAt(enc2) +
        this._keyStr.charAt(enc3) + this._keyStr.charAt(enc4);

    }

    return output;
  },

  // public method for decoding
  decode : function (input) {
    var output = "";
    var chr1, chr2, chr3;
    var enc1, enc2, enc3, enc4;
    var i = 0;

    input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");

    while (i < input.length) {

      enc1 = this._keyStr.indexOf(input.charAt(i++));
      enc2 = this._keyStr.indexOf(input.charAt(i++));
      enc3 = this._keyStr.indexOf(input.charAt(i++));
      enc4 = this._keyStr.indexOf(input.charAt(i++));

      chr1 = (enc1 << 2) | (enc2 >> 4);
      chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
      chr3 = ((enc3 & 3) << 6) | enc4;

      output = output + String.fromCharCode(chr1);

      if (enc3 != 64) {
        output = output + String.fromCharCode(chr2);
      }
      if (enc4 != 64) {
        output = output + String.fromCharCode(chr3);
      }
    }
    //output = Base64._utf8_decode(output);
    return output;
  },

  // private method for UTF-8 encoding
  _utf8_encode : function (string) {
    string = string.replace(/\r\n/g,"\n");
    var utftext = "";

    for (var n = 0; n < string.length; n++) {
      var c = string.charCodeAt(n);
      if (c < 128) {
        utftext += String.fromCharCode(c);
      }
      else if((c > 127) && (c < 2048)) {
        utftext += String.fromCharCode((c >> 6) | 192);
        utftext += String.fromCharCode((c & 63) | 128);
      }
      else {
        utftext += String.fromCharCode((c >> 12) | 224);
        utftext += String.fromCharCode(((c >> 6) & 63) | 128);
        utftext += String.fromCharCode((c & 63) | 128);
      }
    }
    return utftext;
  },

  // private method for UTF-8 decoding
  _utf8_decode : function (utftext) {
    var string = "";
    var i = 0;
    var c = c1 = c2 = 0;

    while ( i < utftext.length ) {
      c = utftext.charCodeAt(i);
      if (c < 128) {
        string += String.fromCharCode(c);
        i++;
      }
      else if((c > 191) && (c < 224)) {
        c2 = utftext.charCodeAt(i+1);
        string += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
        i += 2;
      }
      else {
        c2 = utftext.charCodeAt(i+1);
        c3 = utftext.charCodeAt(i+2);
        string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
        i += 3;
      }
    }
    return string;
  }
}


/////////////////////
//
// PAYPAL
//
/////////////////////

function paypal_start(element, donation) {
  diveboard.mask_file(true, {"z-index": 9000});

  $.ajax({
    url: '/api/paypal/start',
    dataType: 'json',
    type: "GET",
    data: {
      item: element,
      donation: donation
    },
    success: function(data){
      if (data.success) {
        var dg = new PAYPAL.apps.DGFlow({
          trigger: "storage_subscribe_action",
          expType: 'light'
        });
        dg.startFlow(data.url);
      }
      else {
        diveboard.alert(I18n.t(["js","wizard","A technical error occured while initialising the payment process with Paypal."]), data);
        diveboard.unmask_file({"background-color": "#000000"});
      }
    },
    error: function(data) {
      diveboard.alert(I18n.t(["js","wizard","A technical error occured while initialising the payment process with Paypal."]));
      diveboard.unmask_file({"background-color": "#000000"});
    }
  });
}


//////////////////////
//
// PUBLISH TIMELINE
//
//////////////////////

function toggle_fb_spinner(state){
  if ($(".fb_button_text img").length==0 || state == "on"){
    //we need to show the spinner
    padding = ($(".fb_button_text").width() - 43)/2
    $(".fb_button_text").html('<img src="/img/fb_button_spinner.gif" style="padding-left:'+padding+'px; padding-right:'+padding+'px; top: 1px; position: relative;"/>');
  }else{
    //we need to hide the spinner
    $(".fb_button_text").html(I18n.t(["js","wizard","Add to Timeline"]));
  }
}

function fbtimeline_publish(){
  if(privacy == 1){
     diveboard.notify(I18n.t(["js","wizard","Dive not public"]),I18n.t(["js","wizard","We can't publish this dive to your timeline since it's currenlty private. Please make it public first."]));
     return;
  }


  if($(".fb_button_text img").length==0){
    toggle_fb_spinner("on");
    if(G_user_fb_perms_publish_actions != true){

      FB.login(function(response) {
        fb_response = response ;
        FB.api('/v2.0/me/permissions', function (response) {
          if (JSON.stringify(response).match(/\"publish\_actions\":1/)!=null) {
            G_user_fbtoken = fb_response.authResponse.accessToken;
            G_user_fb_perms_publish_actions = true;
            fbtimelinepublish_dive();
            } else {
              // user cancelled login
              diveboard.notify(I18n.t(["js","wizard","Unsufficient privileges"]),I18n.t(["js","wizard","Could not get the adequate permissions to publish this action on your timeline"]));
              toggle_fb_spinner();
              return;
            }
          });
        }, {scope:'publish_actions'});
    }else{
      fbtimelinepublish_dive();
    }



  }else{
    //TODO - the user is frantically clicking while we're working - do something amusing

  }
}

function fbtimelinepublish_dive(){
  $.ajax({
    url: "/api/fb_pushtimeline",
    data: ({
      listDives: [G_dive_id],
      fbtoken: G_user_fbtoken,
      'authenticity_token': auth_token
    }),
    type: "POST",
    dataType: "json",
    error: function(data) {
      diveboard.alert(I18n.t(["js","wizard","A technical error happened while updating the dives."]), null, function(){
        document.location = "/"+G_user_vanity_url+"/bulk?bulk=manager";
      });
      toggle_fb_spinner();
    },
    success: function(data) {
      if(data.success==true && data.updated.length > 0){
        toggle_fb_spinner();
         $(".timeline_info span").hide();
         $(".timeline_info span").first().show().fadeOut(1000);
      }else{
        diveboard.alert(I18n.t(["js","wizard","Your dive could not be pushed on your timeline:"])+' '+data.error, data);
        toggle_fb_spinner();
      }
    }
  });
}

function request_bulk_fb_timeline(force){
  //force = 2 >> republish
  //force = 1 >> publish only new
  //no force  >> notify the user of work if ok

  //we first check for perms
  diveboard.check_or_add_fb_permission(
    "publish_actions",
    function(){
      do_request_bulk_fb_timeline(force)
    },
    function(){
      diveboard.notify(I18n.t(["js","wizard","Could not publish to timeline"]), I18n.t(["js","wizard","Your dives could not be published to your Timeline due to missing Facebook permissions"]));
    });
}
function do_request_bulk_fb_timeline(force){
  list_of_dives = [];
  already_published = [];

  if ($("#wizard_export_list input:checked").length == 0){
    diveboard.notify(I18n.t(["js","wizard","No dives"]),I18n.t(["js","wizard","You must select at least one dive to push to timeline"]));
    return;
  }

  $("#wizard_export_list input:checked").each(function(index, value) {
    if($(value).attr("privacy") == "1"){
      diveboard.notify(I18n.t(["js","wizard","Private dives present in selection"]),I18n.t(["js","wizard","At least one of your dives is private (red lock). Private dives cannot be published to Timeline. You should either unselect them or make them public."]));
      return;
    }

    if(force == 2)
      list_of_dives.push(value.name);
    else if(force == 1 && $(value).attr("graph_id") == "")
      list_of_dives.push(value.name);
    else
      list_of_dives.push(value.name);


    if($(value).attr("graph_id") != ""){
      already_published.push(value.name);
    }
  });
  if(typeof(force) == "undefined"  && already_published.length > 0){
    buttons = {}
    buttons["Republish"] = function(){request_bulk_fb_timeline(2);}
    buttons["Publish only new"] = function(){request_bulk_fb_timeline(1);}
    buttons["Cancel"] = function(){return;}
    diveboard.propose(I18n.t(["js","wizard","Duplicates warning"]), I18n.t(["js","wizard","Some selected dives were already been published on your timeline. In order to prevent the creation of duplicates you can"]), buttons);
    return;
  }

  if (list_of_dives.length == 0){
    diveboard.notify(I18n.t(["js","wizard","Nothing to process"]),I18n.t(["js","wizard","No new dive to publish"]));
    return;
  }

  diveboard.mask_file(true);
  $.ajax({
    url: "/api/fb_pushtimeline",
    data: ({
      listDives: list_of_dives,
      fbtoken: G_user_fbtoken,
      'authenticity_token': auth_token
    }),
    type: "POST",
    dataType: "json",
    error: function(data) {
      diveboard.unmask_file();
      diveboard.alert(I18n.t(["js","wizard","A technical error happened while updating the dives."]), null, function(){
        document.location = "/"+G_user_vanity_url+"/bulk?bulk=manager";
      });
    },
    success: function(data) {
      diveboard.unmask_file();
      if(data.success==true && data.updated.length > 0){
        if(data.not_updated.length > 0){
           diveboard.alert(I18n.t(["js","wizard","The following dives could not be published:"])+' '+data.not_updated.to_String(), data);
        }else{
          diveboard.notify(I18n.t(["js","wizard","Success"]), I18n.t(["js","wizard","%{count} dives were successfully pushed to your Facebook Timeline"], {count: data.updated.length}));
        }
        $.each(data.updated, function(index,value){
          var el = $("#wizard_export_list [name="+value+"]").parent().parent().find(".exitem_fb");
          el.html("");
          $('<div class="fb_button fb_button_small exitem_fb_logo tooltiped"></div>').attr("title", I18n.t(["js","wizard","Published on Facebook"])).appendTo(el);
        });
      }else{
        diveboard.alert(I18n.t(["js","wizard","Your dives could not be pushed on your timeline"])+' '+data.error, data);
      }
    }
  });

}

function ceebox_wizard_popup(idx, img, evt)
{
  $("#cee_wizard").html('');
  var picture_list = $("#galleria-wizard").neat_gallery("list")();

  $.each(picture_list, function(idx, img){
    var a_pict = $('<a>'+I18n.t(["js","wizard","media"])+'</a>').attr('href', img.image);
    $('#cee_wizard').append(a_pict);
  });

  $("#cee_wizard").die('click');

  $($("#cee_wizard a")[idx]).click();
}

function show_buddy_picker(idx){
  if (idx =="0")
    show_diveboard_buddy_picker();
  else if (idx =="1")
    show_facebook_buddy_picker();
  else if (idx == "2")
    show_email_buddy_picker();

}

function show_diveboard_buddy_picker(){
  $('.buddy_table').hide();
  $('.buddy_db').show();
  $('#addbuddy').hide();
  $('.invite_buddy_by_email_div').show();
  $("#invite_buddy_by_email").attr("checked", true).removeAttr("disabled");
}

function show_facebook_buddy_picker() {
    $('.buddy_table').hide();
    $('.buddy_fb').show();
    allow_fb_search();
    $('#addbuddy').hide();
    $('.invite_buddy_by_email_div').hide();
    $("#invite_buddy_by_email").removeAttr("checked");
    if (!G_facebook_buddy_search_init) {
        if (G_user_fbtoken != "")
        facebook_buddy_search_init(G_user_fbtoken);
        else if (FB.getAccessToken() != null)
        facebook_buddy_search_init(FB.getAccessToken());
        else {
            FB.login(function(response) {
                if (response.authResponse) {
                    facebook_buddy_search_init(FB.getAccessToken());
                } else {
                    var actions = {};
                    actions[I18n.t(["js","wizard","Cancel"])] = function() {$(this).dialog("close")};
                    actions[I18n.t(["js","wizard","Retry"])] = function() {
                          $(this).dialog("close");
                          show_facebook_buddy_picker();
                      };
                    diveboard.propose(I18n.t(["js","wizard","Permission required"]), I18n.t(["js","wizard","You cancelled Facebook login - we cannot search facebook"]), actions);
                }
            });
        }
    }
}

function facebook_buddy_search_init(token){
  G_facebook_buddy_search_init = true;
  $("#buddy-fb-name").autocomplete({
    source: function(request, response){
      console.log("request: "+JSON.stringify(request));
      FB.api({
        method: 'fql.query',
        query: 'SELECT name,uid FROM user WHERE uid IN (select uid2 from friend where uid1=me()) AND strpos(lower(name),lower(\''+request.term+'\')) >=0'
      },
      function(r) {
        var friends = $.map(r,function(item){return {id: item.uid, name: item.name}});
        console.log(JSON.stringify(friends));
        global_fb_search(friends, request, token, response);
      });
    },
    minLength: 2,autoFocus: true,
    select: function(event, ui){
      $("#buddy-fb-name-hidden").attr("fb_id", ui.item.fb_id);
      $("#buddy-fb-name-hidden").attr("name", ui.item.value);
      add_buddy();
      $("#buddy-fb-name-hidden").attr("fb_id", "");
      $("#buddy-fb-name-hidden").attr("name", "");
      $("#buddy-fb-name").val("");
    },
    close: function(event, ui){$("#buddy-fb-name").val("");}
  });

}

function global_fb_search(friends, request, token, response){
  $.ajax({
    url:"https://graph.facebook.com/v2.0/search",
    data:{
      q: request.term,
      access_token:token,
      type:"user"
    },
    dataType: "jsonp",
    success: function(data){
      $.each(data.data, function(idx,item){friends.push(item);});
      console.log(JSON.stringify(friends));
      response( $.map(friends, function( item ) {
        return {
          label: "<img src='https://graph.facebook.com/v2.0/"+item.id+"/picture?type=square' class='buddy_picker_list'/>"+"<span class='buddy_picker_list_span'>"+item.name+"</span>",
          value: item.name,
          fb_id: item.id
        }
      }));
    },
    error: function(data) { diveboard.alert(I18n.t(["js","wizard","A technical error happened while trying to connect to Facebook."]));
    return [];
    }
  });
}

function show_email_buddy_picker(){
  $('.buddy_table').hide();
  $('.buddy_manual').show();
  $('#addbuddy').show();
  $('.invite_buddy_by_email_div').show();
  $("#invite_buddy_by_email").removeAttr("CHECKED").attr("DISABLED","true");
}

function check_notify_buddy(el){
  var email =$(el).val();
  if( email.toLowerCase().match(/^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$/) && $(".invite_buddy_by_email_div").hasClass("disabled"))
  {
    $(".invite_buddy_by_email_div").removeClass("disabled");
    $("#invite_buddy_by_email").removeAttr("DISABLED").attr("CHECKED","true");

  }else if (!email.toLowerCase().match(/^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$/)){
    $(".invite_buddy_by_email_div").addClass("disabled");
    $("#invite_buddy_by_email").removeAttr("CHECKED").attr("DISABLED","true");
  }
}

function create_species_minipicker(o){
  //setting a propose dialog box with proper width/height

  var width = 680;
  var height = 200;
  var left = 222;

  buttons = {}
  buttons["OK"] = function(){
    console.log("adding species");
    //get the list, update the counters, enable subsequent saves
    var holder = $(o).parents(".wpl_bloc").first();
    var species_list=[];
    if ($("#dialog-global-notify .add_species_button.orange").length == 0){
      holder.find("span.selected_species").html("None");
      holder.find("p.selected_species_list").empty();
    }else{
      holder.find("span.selected_species").html($("#dialog-global-notify .add_species_button.orange").length);
      var sp_list=""
      $("#dialog-global-notify .add_species_button.orange").each(function(index,value){
        if (index>0)
          sp_list+=", ";
        var data = JSON.parse($(value).attr("data"))
        if(data.preferred_name != undefined){
          sp_list += data.preferred_name;
          species_list.push({id: data.id, name: data.preferred_name});
        }else{
          sp_list += data.sname;
          species_list.push({id: data.id, name: data.sname});
        }
      });
      holder.find("p.selected_species_list").html(sp_list);
      holder.find("p.selected_species_list").attr("data", JSON.stringify(species_list));
    }
  }
  buttons[I18n.t(["js","wizard","Cancel"])] = function(){return;}

  if (G_dive_fishes.length <=4){
    width = 170*G_dive_fishes.length+40;
    if (width < 400) width = 400;
    var left = 222+(4-G_dive_fishes.length)*85;
      diveboard.propose(I18n.t(["js","wizard","Tag species in media"]),'<p class="dialog-text-highlight">'+I18n.t(["js","wizard","To add more species to this selection head to the \"Species\" Tab"])+'</p><div class="species_list" style="width:'+width+'px"></div>', buttons);
    $("#dialog-global-notify").parent().css({width: width+40+"px", left: left+"px"});
  }else{
    height = 400;
      diveboard.propose(I18n.t(["js","wizard","Tag species in media"]),'<p class="dialog-text-highlight">'+I18n.t(["js","wizard","To add more species to this selection head to the \"Species\" Tab"])+'</p><div class="species_list" style="height:400px; width: 720px;"></div>',buttons);
    $("#dialog-global-notify").parent().css({width: "780px", left: left+"px"});
  }


  var uid = MD5($($(o).parents("div")[1]).attr("id"));
  var target = $("#dialog-global-notify .species_list");
    try{
      var data = JSON.parse($(o).parents("div").first().find("p.selected_species_list").attr("data"));
      selected_species = data.map(function(i){return i.id;});
  }catch(e){
     selected_species = [];
  }
  var position = {left: $(o).offset().left, top: ($(o).offset().top+$(o).height())};
  build_minipicker(uid, target, G_dive_fishes, selected_species, null);
  target.jScrollPane({showArrows: false, hideFocus:true});
}

function remove_species_from_pictures(id){
 $.each($(".wpl_bloc"), function(index, value){
   var data = JSON.parse($(value).find("p.selected_species_list").attr("data"));
   var data_new = [];
   $.each(data, function(index, value){
     if(value.id != id)
       data_new.push(value);
     });
  $(value).find("p.selected_species_list").attr("data", JSON.stringify(data_new));
  update_picture_species_list_from_data(value);
 });
}

function update_picture_species_list_from_data(element){
  //gets the species list from the data field and updated the count and the names in the list
  var species = JSON.parse($(element).find("p.selected_species_list").attr("data"));
  var holder = $(element);
  if(species.length >0){
    var species_names = "";
    $.each(species, function(index, value){
     if (index > 0)
       species_names += ", ";
     species_names += value.name;
    });
    holder.find("p.selected_species_list").html(species_names);
    holder.find("span.selected_species").html(species.length);
  }else{
     holder.find("p.selected_species_list").empty();
     holder.find("span.selected_species").html("None");
  }
}

function initialize_dive_review()
{
  $(".hover-star").rating({
    focus: function(value, link){
      var tip = $(this).closest('tr').find('.tooltip_star');
      tip[0].data = tip[0].data || tip.html();
      tip.html(link.title || 'value: '+value);
    },
    blur: function(value, link){
      var tip = $(this).closest('tr').find('.tooltip_star');
      tip.html(tip[0].data || '');
    }
  });
  // $(".hover-star").rating({
  //   callback: function(value, link)
  //   {
  //     alert(value);
  //   }
  // });
  $("#wizard-review").change(function()
  {
    if ($(this).find(':selected').val() != "")
    {
      $("#wizard_star_" + $(this).find(':selected').val()).show();

      $("#wizard-review option[value='" + $(this).find(':selected').val() + "']").remove();
      $(this).find(':selected').attr('selected', false);
    }
     if ($("#wizard-review").children('option').length == 1)
       $("#wizard-criteria").hide();
  });
  if ($("#wizard-review").children('option').length == 1)
       $("#wizard-criteria").hide();

  // if ($("#wizard_star_wreck").)
  // $("#wizard_star_wreck").hide();
  // $("#wizard_star_bigfish").hide();
}
