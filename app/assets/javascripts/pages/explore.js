var map, map_overlay, marker_highlight, marker_lowlight, marker_shadow, marker_shop_highlight, marker_shop_lowlight, marker_shop_shadow, geocoder;
var dbx;
var prevent_further_spot_requests = false;
var prevent_further_spot_grouping = false;
var G_search_map_ajax_requests = [];
var G_search_search_ajax_requests = [];

var G_cluster_zindex_focus = 60;
var G_cluster_zindex_highlight=50;
var G_cluster_zindex_lowlight=10;
var G_min_zoom_shops=10;

var G_root_url = "https://www.diveboard.com";
var G_locale_root_url = G_root_url;

var G_max_items=70;
var G_all_spots_mark = {};
var G_all_spots_html = {};
var G_all_location_html = {};
var G_all_region_html = {};
var G_all_country_html = {};
var G_all_location_bounds = {};
var G_all_region_bounds = {};
var G_all_country_bounds = {};

var G_search_pending = null;

var G_current_highlight_shop_filter = null;
var G_panel2_history = [];
var G_panel2_history_push = true;
var G_panel2_history_position = 0;

function initialize(params) {
  //document.domain = "diveboard.com";  // this made selenium fail
  G_root_url = params.root_url;
  G_locale_root_url = params.locale_root_url;
  //do not auto scan : it causes lags...
  G_prevent_scan = true;

  //Hack-around for IE: if CORS is not supported then get everything from same server
  if (!jQuery.support.cors) G_balanced_roots = [ "//"+window.location.host+"/" ];

  //keep url if there are stuff that are meaningful
  if(window.history.pushState && !window.location.href.match(/\/explore\/spots\/.+/) ){
    $("#xp_p2_like").hide();
    window.history.pushState("", "", "/explore");
  }


  dbx = new diveboard.dbxplore({
    'onDataReady': function() {
      $('#xp_p1_db_wait').hide();
      display_content();
    }
  });

  diveboard.plusone_go();

  initializeLayout();
  $(window).resize(initializeLayout);


  marker_highlight = new google.maps.MarkerImage('/img/explore/marker.png',
      new google.maps.Size(19, 23),
      new google.maps.Point(0,0),
      new google.maps.Point(10, 28));
  marker_lowlight = new google.maps.MarkerImage('/img/explore/marker_grey.png',
      new google.maps.Size(19, 23),
      new google.maps.Point(0,0),
      new google.maps.Point(10, 28));
  marker_shadow = new google.maps.MarkerImage('/img/explore/marker_shadow.png',
      new google.maps.Size(19, 23),
      new google.maps.Point(0,0),
      new google.maps.Point(5, 23));
  marker_shop_highlight = new google.maps.MarkerImage('/img/explore/marker_shop.png',
      new google.maps.Size(14, 14),
      new google.maps.Point(0,0),
      new google.maps.Point(7, 7));
  marker_shop_lowlight = new google.maps.MarkerImage('/img/explore/marker_shop_grey.png',
      new google.maps.Size(14, 14),
      new google.maps.Point(0,0),
      new google.maps.Point(7, 7));
  marker_shop_shadow = new google.maps.MarkerImage('/img/explore/marker_shop_shadow.png',
      new google.maps.Size(14, 15),
      new google.maps.Point(0,0),
      new google.maps.Point(7, 10));

  geocoder = new google.maps.Geocoder();

  $("#xp_p2h_icon").live('click', hide_panel2);

  $('.xp_panel_tab_link').live('click', function() {
    $(this).closest('.xp_links_container').find(".xp_panel_tab_link").removeClass('selected');
    $(this).addClass('selected');
    clear_panels();
    display_content();
  });

  $('.xp_p1_spot_item').live('click', function(ev){
    toggle_spot_detail($(this).data('xp_data').spot_id);
  });

  $('.xp_p1_shop_item').live('click', function(ev){
    toggle_shop_detail($(this).data('xp_data').shop_id);
  });

  $('.xp_p2_dive_item, .xp_p1_dive_item').live('click', function(ev){
    show_dive_detail($(this).data('xp_data').dive_id);
  });

  $("#xp_panel_2 .xp_panel_tab_link").live('click', function(ev) {
    var tab_id = $(this).attr("id");
    tab_id = tab_id.substr(0, tab_id.length-5) + "_tab";
    $("#xp_panel_2 .xp_result_tab").hide();
    $("#xp_panel_2 #"+tab_id).show();
    initializeLayout();
  });

  $('#xp_p2h_back').live('click', history_back);
  $('#xp_p2h_forward').live('click', history_forward);

  $(".xp_p2_user_item").live("click", function(ev) {
    toggle_user_detail($(this).data("xp_data").user_id);
  });

  $(".xp_p2_spot_item").live("click", function(ev) {
    ev.preventDefault();
    show_spot_detail($(this).data("xp_data").spot_id);
  });

  $(".xp_p2_shop_item").live("click", function(ev) {
    ev.preventDefault();
    show_shop_detail($(this).data("xp_data").shop_id);
  });

  $('.xp_p1_country_item').live('click', show_zone);

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



  $("#xp_p2_img_fold").click(function(ev){
    //folding
    if ($("#xp_p2_img_container").height() > 20) {
      $("#xp_p2_img_container").animate({'max-height':10}, 300, function(){ $("#xp_p2_img_container img").css({'position': 'relative', 'top': 50}); initializeLayout(); })
      $("#xp_p2_img_fold").text('{');
    }
    //expanding
    else {
      $("#xp_p2_img_container img").css({'position': 'relative', 'top': 0});
      $("#xp_p2_img_container").animate({'max-height':293}, 300, initializeLayout)
      $("#xp_p2_img_fold").text('}');
    }
  });

  $("a.zoomUser").live('click', function(ev){
    ev.preventDefault();
    var data = $("#xp_p2h_head").data('xp_data');
    if ('user_id' in data) {
      zoom_on_user(data.user_id);
      var user_spots = {};
      $.each(dbx.users[data.user_id].dives, function(i, d){user_spots[d.spot.id] = true});

      apply_highlight_spots(Object.keys(user_spots));
    }
  });

  map = new google.maps.Map(document.getElementById("map_canvas"), {
    'zoom': 6,
    'minZoom': 2,
    'maxZoom': params.maxZoomLevel,
    'center': new google.maps.LatLng(0,0),
    'streetViewControl': false,
    'keyboardShortcuts': false,
    'zoomControlOptions': { 'position': google.maps.ControlPosition.TOP_RIGHT },
    'mapTypeControlOptions': { 'position': google.maps.ControlPosition.RIGHT_BOTTOM },
    'panControlOptions': { 'position': google.maps.ControlPosition.TOP_RIGHT },
    'mapTypeId': google.maps.MapTypeId.HYBRID
  });
  GP=params;
  if (params.search_address != "") {
	  search_something(params.search_address);
  } else if (params.initial_location.lat_min) {
    var sw = new google.maps.LatLng(params.initial_location.lat_min, params.initial_location.lng_min);
    var ne = new google.maps.LatLng(params.initial_location.lat_max, params.initial_location.lng_max);
    map.panToBounds(new google.maps.LatLngBounds(sw, ne));
    map.fitBounds(new google.maps.LatLngBounds(sw, ne));
  } else {
    map.setCenter(new google.maps.LatLng(params.initial_location.latitude, params.initial_location.longitude));
    map.setZoom(params.initial_location.zoom);
  }

  /*
  google.maps.event.addListener(map, 'load', display_content);
  google.maps.event.addListener(map, 'dragend', display_content);
  google.maps.event.addListener(map, 'click', display_content);
  google.maps.event.addListener(map, 'zoom_changed', function() {//Google maps calls zoom_changed before the map is actually updated....
    zoomChangeBoundsListener = google.maps.event.addListener(map,'bounds_changed',function (event) {
      google.maps.event.removeListener(zoomChangeBoundsListener);
      setTimeout(display_content, 500);
    });
  });
  */

  google.maps.event.addListener(map, 'zoom_changed', function() {//Google maps calls zoom_changed before the map is actually updated....
    var zoomChangeBoundsListener;
    zoomChangeBoundsListener = google.maps.event.addListener(map,'bounds_changed',function (event) {
      google.maps.event.removeListener(zoomChangeBoundsListener);
      if (map.getZoom() >= 10) $("#map_canvas").addClass('bigZoom');
      else $("#map_canvas").removeClass('bigZoom');
    });
  });

  //This object does nothing by itself, but is used for map manipulation
  map_overlay = new google.maps.OverlayView();
  map_overlay.draw = function(){};
  map_overlay.remove = function(){};
  map_overlay.setMap(map);

  ShopMarker.prototype = new google.maps.OverlayView();
  define_shopmarker();


  clusterer = new diveboard.clusters();
  map.overlayMapTypes.insertAt(0, new ClusterOverlay(new google.maps.Size(256, 256), clusterer));

  best_data_overlay = new BestDataOverlay(new google.maps.Size(256, 256), dbx);
  map.overlayMapTypes.insertAt(0, best_data_overlay);


  var onloadListener = google.maps.event.addListener(map,'tilesloaded',function (event) {
    google.maps.event.removeListener(onloadListener);
    //display_content();
    update_perma_link();
  });

  initialize_follow_links();

  $("#xp_panel_2 .xp_result_list").hide();
  $("#xp_panel_2 #xp_p2_info_tab").show();

  $('.autoclear').autoclear();
  $("#xp_p1_search").example($("#xp_p1_search").attr('title'));

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


  //initialize the wiki editor
  $(".xp_wiki_edit").live('click', wiki_edit_popup);

  //Initialize the ad display every 30s
  setInterval(cycle_ads, 30000);
  $(".ad_item").live('click', function(){
    var ad_data = $(this).data('ad');
    if (ad_data.id)
      $.ajax({url: "/api/stats_trace/ad_explore/"+ad_data.id+"/click"});
  });
  setInterval(function(){$.ajax({url: "/api/stats_trace/explore/keep30"})}, 30000);
}


function initializeLayout(){
  var show_panel2 = $("#xp_panel_2").is(':visible');
  $("#footer_container").hide();
  $("#xp_panel_2").show();
  $("#container").css({'width': $(window).width(), 'position':'fixed'});
  //$("#container_search").css({'width': $(window).width(), height: $(window).height(), 'position':'fixed'});
  $("#container_search").css({'width': "100%", height: "100%", 'position':'fixed'});
  $("#map_canvas").css('height', $(window).height() - $("#map_canvas").offset().top - 3 );
  $("#xp_panel_1").css('height', $(window).height() - $("#xp_panel_1").offset().top - 3);
  $("#xp_p1_list").css('height', $("#xp_panel_1").height() + $("#xp_panel_1").offset().top - $("#xp_p1_list").offset().top );
  $("#xp_p1_content").css('height', $("#xp_panel_1").height() + $("#xp_panel_1").offset().top - $("#xp_p1_content").offset().top );
  $("#xp_panel_2").css('height', $(window).height() - $("#xp_panel_2").offset().top - 3 );
  $("#xp_p2_content").css('height', $("#xp_panel_2").height() + $("#xp_panel_2").offset().top - $("#xp_p2_content").offset().top );
  //$("#xp_p2_pages_out").css('height', $("#xp_panel_2").height() + $("#xp_panel_2").offset().top - $("#xp_p2_pages_out").offset().top );
  $('#xp_p1_list').jScrollPane({'showArrows': true, 'hideFocus':true, 'contentWidth':'299px', 'enableKeyboardNavigation': false});
  $('.xp_scrollable:visible').jScrollPane({'showArrows': true, 'hideFocus':true, 'contentWidth':'299px'});
  $('.jspArrowUp').text('}').addClass('symbol').css({});
  $('.jspArrowDown').text('{').addClass('symbol').css({'text-indent': 0, 'color': '#5c5c5c'});

  $("#search_permalink_block").css('top', $(window).height() - $("#xp_panel_1").offset().top - 21);

  $(".panic_button").css('top', '10px'); //TODO replace panic button in top bar
  if (!show_panel2) $("#xp_panel_2").hide();
  update_map_width();
  manage_responsiveness();
}

function manage_responsiveness(){
  console.log("poney");
  if($(window).width()<730){
    console.log("in");
    
    //if($("#xp_panel_1").attr('clicked')==undefined || $("#xp_panel_1").attr('clicked')==false)
    $("#xp_panel_1").hide();
    $("#xp_panel_1_mob").show();

    /*
    $("#xp_panel_1").css('width','100%');
    $("#xp_panel_1").css('height','400px');
    $("#xp_panel_1").css('bottom','0px');
    $("#xp_panel_1").css('top','');
    $('#xp_p1_content').css('padding','10px');
    $("#xp_p1_head").hide();*/
    if($("#xp_panel_2").attr('clicked')==undefined || $("#xp_panel_2").attr('clicked')==false)
    $("#xp_panel_2").hide(); 

    $("#show_responisve_menu").show();
    $("#show_responisve_menu").click(function(){
      $("#xp_panel_1").show();
      $("#xp_p1_close").show();
      $("#xp_p1_close").click(function(){
        $("#xp_panel_1").hide();
        $("#xp_panel_1").attr('clicked',false);
      })
      $("#xp_panel_1").attr('clicked',true);
    });
    $("#map_canvas").css('width',$(window).width()-30);
    $("#map_canvas").css('height',$(window).height()-($(window).height()/2)-10);
    $("#map_canvas").css('left','10px');
    $("#map_canvas").css('right','10px');

  }
  else{
    $("#xp_panel_1").show();
    $("#xp_p1_close").hide();
    $("#map_canvas").css('left','');
    $("#map_canvas").css('right','0px');
  }

}



////////////////////////
//
// CONTROL TOWER
//
////////////////////////

function display_content(all)
{
  if (diveboard.postpone_me(500)) return;

  if (typeof all == 'undefined') all = false

  if (!dbx.ready()) return;

  // First, display all the markers
  var bounds = map.getBounds();
  if (typeof bounds == 'undefined') return;

  //if (map.getZoom() <= 5) all = true;
  var spots = best_data_overlay.localSpots();

  //update the ads if no adds was already displayed
  append_ads_if_empty();

  //display the shops
  var shops = [];
  if (map.getZoom() >= G_min_zoom_shops) {
    shops = dbx.shops_in(get_covered_bounds());

    for (var i in shops) {
      var shop = shops[i];
      if (!shop.marker)
      {
        var result = add_marker_shop(shop);
        shop.marker = result.marker;
      }
      shop.marker.show();
    }
  } else
    for (var i in dbx.shops) {
      if (dbx.shops[i].marker && (G_current_highlight_shop_filter == null || !G_current_highlight_shop_filter.apply(this,[i,dbx.shops[i]])) )
        dbx.shops[i].marker.hide();
    }


  //SPOTS DISPLAY
  if (($("#xp_panel_1 #xp_p1_tabs .xp_panel_tab_link.selected").attr('id') == "xp_p1_spots_link" &&
    $(window).width()> 730)|| ($("#xp_panel_1_mob #xp_p1_tabs .xp_panel_tab_link.selected").attr('id') == "xp_p1_spots_link" &&
    $(window).width()< 730)) {
    var list_html = $("<div/>");
    var spot_count = 0;

    $.each(spots.sort( function(a,b){ return(b.score-a.score)}), function(i,spot){
      spot_count++;
      if (spot_count < G_max_items) {
        if (!G_all_spots_html[spot.id]){
          var content = [ location_string_of_spot(spot) ];
          if (spot.public_dive_count > 0)
            content.push(I18n.t(['js', 'explore', '%{count} dives'], {count: spot.public_dive_count}));

          var img_src = null;
          if (spot.thumbnail)
            img_src = spot.thumbnail;
          else
            for (var i in spot.dives) {
              var dive = spot.dives[i];
              if (dive.featured_picture_thumbnail) {
                img_src = dive.featured_picture_thumbnail;
                break;
              }
            }

          G_all_spots_html[spot.id] = JST['explore/_xp_panel1_list_item']({
              'class_tag': 'xp_p1_spot_item',
              'title': spot.name,
              'img_src': img_src,
              'content': content.join("<br/>"),
              'with_arrow': true
            });
        }

        list_html.append($(G_all_spots_html[spot.id]).data('xp_data', {'spot_id': spot.id}));
      }
    });

    clear_panels();
    $("#xp_p1_tab ul").append(list_html);

    initializeLayout();
    panel1_zoom_to_selected();
  }

  //COUNTRY DISPLAY
  else if (($("#xp_panel_1 .xp_panel_tab_link.selected").attr('id') == "xp_p1_countries_link" &&
    $(window).width()> 730)|| ($("#xp_panel_1_mob #xp_p1_tabs .xp_panel_tab_link.selected").attr('id') == "xp_p1_countries_link" &&
    $(window).width()< 730)) {
    var list_html = $("<div/>");
    var spot_count = 0;

    var countries = best_data_overlay.localCountries();

    for (var i in countries){
      var country = dbx.countries[countries[i].id];

      var content = [];
      content.push(I18n.t(['js', 'explore', '%{count} dives'], {count: country.dive_ids.length}));

      if (country.name != '' && country.name != null && country.name != 'null') {
        if (!('_html' in country))
          country._html = $(JST['explore/_xp_panel1_list_item'](
            {
              'class_tag': 'xp_p1_country_item',
              'title': country.name,
              'content': content.join(" - "),
              'img_src': country.thumbnail,
              'with_arrow': false
            }));
        else
          country._html.find('.xp_pli_content').html(content.join(" - "));

        var country_bounds = null;
        if (country.bounds) {
          country_bounds = new google.maps.LatLngBounds(
            new google.maps.LatLng(country.bounds.southwest.lat, country.bounds.southwest.lng),
            new google.maps.LatLng(country.bounds.northeast.lat, country.bounds.northeast.lng)
          );
        }
        country._html.data('xp_data', {'zone':"country", 'name': country.name, 'blob': country.blob, 'id': country.id, 'bounds': country_bounds});

        list_html.append(country._html);
      }
    }

    $("#xp_p1_tab ul").html(list_html);

    initializeLayout();
    panel1_zoom_to_selected();
  }

  //DIVES DISPLAY
  else if (($("#xp_p1_tabs .xp_panel_tab_link.selected").attr('id') == "xp_p1_dives_link" && 
    $(window).width()> 730) || ($("#xp_panel_1_mob #xp_p1_tabs .xp_panel_tab_link.selected").attr('id') == "xp_p1_dives_link" &&
    $(window).width()< 730)){

    var dives = sort_dive_by_score(best_data_overlay.localDives());
    var list_html = $("<div/>");
    var dives_count = 0;
    clear_panels();
    $.each(dives, function(i,dive){
      if (dives_count ++ > 30) return;

      try {
        var image = "/"+dive.user.vanity_url+"/"+dive.id+"/profile.png?g=xxsmall_blue";
        try {
          if (dive.featured_picture_thumbnail && dive.featured_picture_thumbnail != "")
            image=dive.featured_picture_thumbnail;
        } catch(ex){}
        var dive_html = JST['explore/_xp_panel1_list_item'](
          {
            'class_tag': 'xp_p1_dive_item',
            'title': dive.spot.name,
            'img_src': image,
            'content': dive.spot.area_name+"<br/>"+dive.date + " - " + Math.round(dive.duration)+" min - "+Math.round(dive.maxdepth)+" m<br/><a href='"+dive.permalink+"' target='_blank'>View in logbook</a><br/>",
            'with_arrow': true
          });
        $("#xp_p1_tab ul").append($(dive_html).data('xp_data', {'dive_id': dive.id, 'spot_id': dive.spot.id}));
      } catch(ex) {
        if (console && console.log)
          console.log(ex);
          LAST_EX = ex;
          console.log(dive);
      }

    });

    //TODO closest divers/dives
    if (dives_count==0)
      $("#xp_p1_tab ul").append("<li>"+I18n.t(["js","explore","No dives have been recorded dives on diveboard here..."])+"</li>");
  }

  //SHOPS DISPLAY
  else if (($("#xp_p1_tabs .xp_panel_tab_link.selected").attr('id') == "xp_p1_shops_link" &&
    $(window).width()> 730)|| ($("#xp_panel_1_mob #xp_p1_tabs .xp_panel_tab_link.selected").attr('id') == "xp_p1_shops_link" &&
    $(window).width()< 730)) {
    var shops = best_data_overlay.localShops();
    var list_html = $("<div/>");
    var shops_count = 0;
    clear_panels();
    $.each(shops, function(i,shop){
      if (shops_count ++ > 30) return;
      try {
        var content = "";
        if (shop.overall_rating) {
          content += "<span class='review_stars' style='position: relative; top: 3px;'>"
          var c = mark_to_stars(shop.overall_rating);
          for (var k in c)
            content +="<span class='"+c[k]+"'/>";
          content += "</span>  "
        }
        if (shop.dive_ids && shop.dive_ids.length>0) content += I18n.t(['js', 'explore', '%{count} dives'], {count: shop.dive_ids.length});
        if (shop.positive_reviews > 0 || shop.negative_reviews > 0) {
          content += "<br/><img src='/img/icons/vote_positive.png' style='position:relative; top:3px'/> "+I18n.t(['js', 'explore', '<b>%{count}</b> positive review'], {count: shop.positive_reviews});
          content += "<br/><img src='/img/icons/vote_negative.png' style='position:relative; top:3px'/> "+I18n.t(['js', 'explore', '<b>%{count}</b> negative review'], {count: shop.negative_reviews});
        }
        //if (shop.overall_rating > 0) {
        //  content += "<br/>Overall rating: "+Math.round(10*shop.overall_rating)/10+"/5";
        //}
        if (shop["can_sell?"]) {content += "<a href='"+shop.fullpermalink+"#services' class='can_sell' target='_blank'> </a>";}
        var img_src = shop.logo_url;
        if (shop.logo_url.match("no_picture.png")) img_src = null;
        var shop_html = JST['explore/_xp_panel1_list_item'](
          {
            'class_tag': 'xp_p1_shop_item',
            'title': shop.name,
            'img_src': img_src,
            'content': content,
            'with_arrow': false
          });
        $("#xp_p1_tab ul").append($(shop_html).data('xp_data', {'shop_id': shop.id}));
      } catch(ex) {
        if (console && console.log)
          console.log(ex);
      }
    });

    //TODO closest divers/dives
    if (shops_count==0)
      $("#xp_p1_tab ul").append("<li>"+I18n.t(["js","explore","We don't know any dive shop there. Contact us if you would like to add one here!"])+"</li>");
  }

  initializeLayout();
  var selected = $('#xp_p2h_head').data('xp_data');
  var key = null;
  for (key in selected) {}
  if (key)
    $("#xp_panel_1 .xp_panel_list_item").each(function(i,e){
      if ($(e).data('xp_data')[key] == selected[key])
        $(e).addClass('selected');
    });
  panel1_zoom_to_selected();
  update_perma_link();
}



/////////////////////////
//
// PANEL 1
//
/////////////////////////

function clear_panels()
{
  //stop all requests
  for (var i in G_search_map_ajax_requests)
    G_search_map_ajax_requests[i].abort();
  G_search_map_ajax_requests = [];
  $("#search_in_progress_icon").hide();

  $("#xp_p1_tab ul li").removeClass("selected");
  $("#xp_p1_tab ul li").detach();

  initializeLayout();
  //clear_markers();
}


function panel1_zoom_to_selected()
{
  try {
    $("#xp_p1_list").data('jsp').scrollToElement($("#xp_p1_list li.xp_panel_list_item.selected"));
  } catch(e){}
}



////////////////////////
//
// ACTIONS ON CLICKS
// PANEL 2
//
////////////////////////


function history_push(page){
  if (!G_panel2_history_push) return;
  G_panel2_history=G_panel2_history.slice(0, G_panel2_history_position+1);
  G_panel2_history.push(page);
  G_panel2_history_position = G_panel2_history.length-1;
  refresh_back_forward();
}

function history_clear(){
  G_panel2_history_position = 0;
  G_panel2_history = [];
  refresh_back_forward();
}

function history_back(){
  if (G_panel2_history_position <= 0) return;
  G_panel2_history_position--;
  G_panel2_history_push = false;
  var page = G_panel2_history[G_panel2_history_position];
  if ('spot' in page)
    show_spot_detail(page.spot.id);
  else if ('user' in page)
    show_user_detail(page.user.id);
  else if ('dive' in page)
    show_dive_detail(page.dive.id);
  else if ('zone' in page)
    show_zone(page);
  else if ('shop' in page)
    show_user_detail(page.user.id);
  G_panel2_history_push = true;
  refresh_back_forward();
}

function history_forward() {
  if (G_panel2_history_position >= G_panel2_history.length-1) return;
  G_panel2_history_position++;
  G_panel2_history_push = false;
  var page = G_panel2_history[G_panel2_history_position];
  if ('spot' in page)
    show_spot_detail(page.spot.id);
  else if ('user' in page)
    show_user_detail(page.user.id);
  else if ('dive' in page)
    show_dive_detail(page.dive.id);
  else if ('zone' in page)
    show_zone(page);
  G_panel2_history_push = true;
  refresh_back_forward();
}

function refresh_back_forward() {
  if (G_panel2_history_position < G_panel2_history.length-1) $("#xp_p2h_forward").show();
  else $("#xp_p2h_forward").hide();
  if (G_panel2_history_position > 0) $("#xp_p2h_back").show();
  else $("#xp_p2h_back").hide();
}



function toggle_spot_detail(spot_id)
{
  var data = $("#xp_p2h_head").data('xp_data');
  if ($("#xp_p2h_head").is(':visible') && data && data.spot_id == spot_id)
    hide_panel2();
  else
    show_spot_detail(spot_id);
}

function toggle_user_detail(user_id)
{
  var data = $("#xp_p2h_head").data('xp_data');
  if ($("#xp_p2h_head").is(':visible') && data && data.user_id == user_id)
    hide_panel2();
  else {
    show_user_detail(user_id);

    var user_spots = {};
    $.each(dbx.users[user_id].dives, function(i, d){if (d && d.spot && d.spot.id) user_spots[d.spot.id] = true});
    apply_highlight_spots(Object.keys(user_spots));
  }
}

function toggle_shop_detail(shop_id)
{
//  var data = $("#xp_p2h_head").data('xp_data');
//  if ($("#xp_p2h_head").is(':visible') && data && data.spot_id == spot_id)
//    hide_panel2();
//  else
    show_shop_detail(shop_id);
}


function show_zone(data)
{
  if (typeof data != 'object' || !('zone' in data))
    data = $(this).data('xp_data');
  if (data.bounds)
    map.fitBounds(data.bounds);
  else
    $.post( '/api/js_logs', {"location": window.location.href, "message": "No bounds found for country"+data.name });

  var type;
  if (data.zone == 'country') type = 'countries';
  else if (data.zone == 'location') type = 'locations';
  else if (data.zone == 'region') type = 'regions';
  else return;

  var zone = dbx[type][data.id];

  //Highlight the spot in the list
  $("#xp_p1_list ul li").removeClass('selected');
  $("#xp_p1_list ul li").each(function(i, e){
    try {
      var d = $(e).data('xp_data');
      if (d.zone == data.zone && d.blob == data.blob) {
        $(e).addClass('selected');
        panel1_zoom_to_selected();
      }
    } catch(ex) {}
  });

  $("#xp_p2h_head").text(zone.name);
  //data.id = zone.id; // save the id - will be used for wiki edit

  $("#xp_p2h_head").data('xp_data', data);
  setup_follow_button(data.zone+'_id', zone.id);
  var img_src = zone.large;

  $("#xp_p2_img").hide();
  if (img_src) {
    $("#xp_p2_img img").attr('src', img_src).load(function(){
      $("#xp_p2_img_container").css({'max-height':293});
      $("#xp_p2_img_fold").text('}');
      $("#xp_p2_img").show();
      initializeLayout();
    });
  }
  $(".xp_p2_info_tab_wiki").attr("obj_id", zone.id);
  $(".xp_p2_info_tab_wiki").attr("obj_type", $("#xp_p2h_head").data('xp_data').zone);

  //filling in the main form in panel 2
  $("#xp_p2_pages").html("");
  $("#xp_p2_pages").append(JST['explore/_xp2_zone']({zone:zone}));

  history_push( data );


  $(".xp_wiki_contribute").hide();
  $(".xp_p2_info_tab_wiki_edit").hide();

  if (!('wiki_html' in zone)){
    var req = {};
    req[type] = [zone.id];
    dbx.detail(req, (function(zone){ return function(){
      if (zone.wiki_html)
        $(".xp_p2_info_tab_wiki_edit").show();
      else{
        $(".xp_wiki_contribute").show();
        $(".xp_p2_info_tab_wiki").hide();
      }
      $(".xp_p2_info_tab_wiki").attr("obj_id", zone.id);
      $(".xp_p2_info_tab_wiki").attr("obj_type", $("#xp_p2h_head").data('xp_data').zone);
      if ($("#xp_p2h_head").data('xp_data').blob != zone.blob) return;
      $("#xp_p2_pages").html("");
      console.log(zone);
      Z = zone;
      $("#xp_p2_pages").append(JST['explore/_xp2_zone']({zone:zone}));
      $("#xp_p2_info_link").click();
      $(".xp_p2_info_tab_wiki").addClass("haswiki");
      $(".xp_p2_info_tab_wiki").attr("obj_id", zone.id);
      $(".xp_p2_info_tab_wiki").attr("obj_type", $("#xp_p2h_head").data('xp_data').zone);

      $("#xp_p2_dives_link").hide();
      for (var i in zone.dives) {
        $("#xp_p2_dives_link").show();
        break;
      }

      //highlight clusters
      if (zone.spot_ids) apply_highlight_spots(zone.spot_ids);

      initializeLayout();
    }})(zone));
  }else{
    if (zone.wiki_html){
      $(".xp_p2_info_tab_wiki_edit").show();
      $(".xp_p2_info_tab_wiki").addClass("haswiki")
    }
    else{
      $(".xp_wiki_contribute").show();
      $(".xp_p2_info_tab_wiki").hide();
    }
    $(".xp_p2_info_tab_wiki").attr("obj_id", zone.id);
    $(".xp_p2_info_tab_wiki").attr("obj_type", $("#xp_p2h_head").data('xp_data').zone);

    //highlight clusters
    if (zone.spot_ids) apply_highlight_spots(zone.spot_ids);
  }


  $("#xp_p2_tabs .xp_panel_tab_link").removeClass('selected');
  $("#xp_p2_info_link").addClass('selected');
  show_panel2();//function(){center_if_not_visible(G_all_spots_mark[spot_id].getPosition())});
  $("#xp_panel_2 .xp_result_tab").hide();
  $("#xp_p2_info_tab").show();
  initializeLayout();

  $("#xp_p2_info_link").show();

  $("#xp_p2_dives_link").hide();
  for (var i in zone.dives) {
    $("#xp_p2_dives_link").show();
    break;
  }
  $("#xp_p2_divers_link").hide();
  for (var i in zone.users) {
    $("#xp_p2_divers_link").show();
    break;
  }
  if (img_src) $("#xp_p2_pictures_link").show();
  else  $("#xp_p2_pictures_link").hide();
  $("#xp_p2_img").hide();

  //Changing the url
  if(window.history.pushState) window.history.pushState("", "", zone.permalink);
  $("#xp_p2_like").html('<div class="g-plusone" data-size="medium" data-href="'+zone.fullpermalink+'"></div></div>'+
    '<div class="platform"><fb:like href="'+zone.fullpermalink+'" width="90" layout="button_count" show_faces="false" send="false"></fb:like></div><div class="platform">');
  if (typeof FB !== 'undefined') FB.XFBML.parse(document.getElementById('xp_p2_like'));
  diveboard.plusone_go();
  $("#xp_p2_like").show();
  ga('send', 'pageview', zone.permalink);

  update_perma_link(true);
}

function show_spot_detail(spot_id, completing)
{
  var spot = dbx.spots[spot_id];

  if (!spot) {
    //spot was not loaded, we need to fetch it from the server
    dbx.detail({'spots': [spot_id]}, (function(id){return function(){show_spot_detail(id, false)}})(spot_id));
    show_loading_detail();
    return
  }

  if (!completing && spot.flavour != 'search_full') {
    //spot was not loaded, we need to fetch it from the server
    dbx.detail({'spots': [spot.shaken_id]}, (function(id){return function(){show_spot_detail(id, true)}})(spot_id));
  }


  //When completing, some initialisation should not be done
  if (!completing){

    //Highlight the spot in the list
    $("#xp_p1_list ul li").removeClass('selected');
    $("#xp_p1_list ul li").each(function(i, e){
      try {
        if ($(e).data('xp_data').spot_id == spot_id) {
          $(e).addClass('selected');
          panel1_zoom_to_selected();
        }
      } catch(ex) {}
    });

    $("#xp_p2h_head").text(spot.name);
    $("#xp_p2h_head").data('xp_data', {'spot_id': spot_id});
    setup_follow_button('spot_id', spot_id);

    //filling in the main form in panel 2
    $("#xp_p2_pages").html("");
    console.log(spot);
    $("#xp_p2_pages").append(JST['explore/_xp2_spotinfo']({spot:spot}));
    history_push( {'spot': spot} );


    //Setting the image on panel 2
    var img_src = spot.large;
    if (!img_src)
      for (var i in spot.dives) {
        var dive = spot.dives[i];
        if (dive.featured_picture_medium) {
          spot.featured_picture_dive = dive;
          img_src = dive.featured_picture_medium;
          break;
        }
      }
    $("#xp_p2_img").hide();
    initializeLayout();
    $("#xp_p2_img img").attr('src', img_src).load(function(){
      $("#xp_p2_img_container").css({'max-height':293});
      $("#xp_p2_img_fold").text('}');
      $("#xp_p2_img").show();
      initializeLayout();
    });

    if (img_src) $("#xp_p2_pictures_link").show();
    else  $("#xp_p2_pictures_link").hide();

    $("#xp_p2_like").hide();
    if(window.history.pushState) window.history.pushState("", "", spot.permalink);
    ga('send', 'pageview', spot.permalink);
  }


  //filling in the picture panel
  if ($("#xp_p2h_head").data('xp_data').spot_id != spot_id) return;
  if (dbx.spots[spot_id].best_pics) {
    $("#xp_p2_pictures_tab").html("");
    $.each( dbx.spots[spot_id].best_pics, function(i, pic) {
      var im = $("<img/>").attr("src", pic.thumbnail);
      if (pic.permalink != "#")
        $("<a target='_blank'/>").attr('href', pic.permalink).append(im).appendTo("#xp_p2_pictures_tab");
      else
        im.appendTo("#xp_p2_pictures_tab");
    });
  }
  else {
    $("#xp_p2_pictures_tab").html("<div style='text-align: center; margin: 30px;'><img src='/img/transparent_loader_2.gif'/></div>");
  }


  //refilling parts of the DOM in case of completing
  if (completing) {
    var dom = $("<div/>").html(JST['explore/_xp2_spotinfo']({spot:spot}));
    var dom_dives = dom.find('[id=xp_p2_dives_tab]');
    $("#xp_p2_pages #xp_p2_dives_tab").html(dom_dives);
    var dom_users = dom.find('[id=xp_p2_divers_tab]');
    $("#xp_p2_pages #xp_p2_divers_tab").html(dom_users);
  }


  if (!completing){
    $("#xp_p2_tabs .xp_panel_tab_link").removeClass('selected');
    $("#xp_p2_info_link").addClass('selected');
    show_panel2();//function(){center_if_not_visible(G_all_spots_mark[spot_id].getPosition())});
    $("#xp_panel_2 .xp_result_tab").hide();
    $("#xp_p2_info_tab").show();
  }

  initializeLayout();

  $("#xp_p2_info_link").show();

  $("#xp_p2_dives_link").hide();
  for (var i in spot.dives) {
    $("#xp_p2_dives_link").show();
    break;
  }
  $("#xp_p2_divers_link").hide();
  for (var i in spot.users) {
    $("#xp_p2_divers_link").show();
    break;
  }
  if (!completing){
    center_if_not_visible(new google.maps.LatLng(spot.lat, spot.lng));
    for (var i in G_all_spots_mark) {
      G_all_spots_mark[i].setMap(null);
      delete G_all_spots_mark[i];
    }
    var marker = new ShopMarker(map, new google.maps.LatLng(spot.lat, spot.lng), '/img/explore/marker.png', spot.name, "-12px", "-16px");
    marker.setZIndex(G_cluster_zindex_focus);
    G_all_spots_mark[spot.id] = marker;
    make_marker_bounce(spot);
    apply_highlight_spots([spot_id]);
    update_perma_link(true);
  }
}



function show_user_detail(user_id)
{
  var user = dbx.users[user_id];

  if (!user) {
    //user was not loaded, we need to fetch it from the server
    dbx.detail({'users': [user_id]}, (function(id){return function(){show_user_detail(id)}})(user_id));
    show_loading_detail();
    return
  }

  //Highlight the spot in the list
  $("#xp_p1_list ul li").removeClass('selected');
  $("#xp_p1_list ul li").each(function(i, e){
    try {
      if ($(e).data('xp_data').user_id == user_id) {
        $(e).addClass('selected');
        //TODO $("#"+tab_id).data('jsp').scrollToElement($("#"+elt_id));
      }
    } catch(ex) {}
  });

  $("#xp_p2h_head").text(user.nickname);
  $("#xp_p2h_head").data('xp_data', {'user_id': user_id});
  if (G_user_id == user_id)
    $('#xp_p2h_follow').hide();
  else
    setup_follow_button('user_id', user_id);

  $("#xp_p2_img").hide();
  initializeLayout();
  $("#xp_p2_img img").attr('src', user.picture_large);
  $("#xp_p2_img img").load(function(){
    $("#xp_p2_img_container").css({'max-height':293});
    $("#xp_p2_img_fold").text('}');
    $("#xp_p2_img").show();
    initializeLayout();
  });

  $("#xp_p2_pages").html('');
  $("#xp_p2_pages").append(JST['explore/_xp2_diver']({user:user}));
  history_push( {'user': user} );

  dbx.detail({'users': [user.shaken_id], 'dives': user.public_dive_ids, 'spots': user.public_spot_ids}, (function(id){return function(){complete_user_detail(id)}})(user.id));

  $("#xp_p2_tabs .xp_panel_tab_link").removeClass('selected');
  $("#xp_p2_info_link").addClass('selected');
  $("#xp_p2_img").show();
  $("#xp_p2_img_container").css({'max-height':293});
  $("#xp_p2_img_fold").text('}');
  show_panel2();
  $("#xp_panel_2 .xp_result_tab").hide();
  $("#xp_p2_info_tab").show();
  $("#xp_p2_info_link").show();
  $("#xp_p2_dives_link").show();
  $("#xp_p2_divers_link").hide();
  $("#xp_p2_pictures_link").show();
  initializeLayout();
  update_perma_link(true);
}


function complete_user_detail(user_id) {
  if ($("#xp_p2h_head").data('xp_data').user_id != user_id) return;
  $("#xp_p2_pictures_tab").html("");
  $.each( dbx.users[user_id].dive_pictures, function(i, pic) {
    var im = $("<img/>").attr("src", pic.thumbnail);
    if (pic.permalink != "#")
      $("<a target='_blank'/>").attr('href', pic.permalink).append(im).appendTo("#xp_p2_pictures_tab");
    else
      im.appendTo("#xp_p2_pictures_tab");
  });
  initializeLayout();
}





function show_dive_detail(dive_id, completing)
{
  var dive = dbx.dives[dive_id];

  if (!dive) {
    //user was not loaded, we need to fetch it from the server
    dbx.detail({'dives': [dive_id]}, (function(id){return function(){show_dive_detail(id, false)}})(dive_id));
    show_loading_detail();
    return
  }

  if (!completing && dive.flavour != 'search_full') {
    //spot was not loaded, we need to fetch it from the server
    dbx.detail({'dives': [dive.shaken_id]}, (function(id){return function(){show_dive_detail(id, true)}})(dive_id));
  }

  //TODO  if ($("#xp_p2h_head").data('xp_data').dive_id != dive_id) return;


  //When completing, some initialisation should not be done
  if (!completing){

    //Highlight the spot in the list
    $("#xp_p1_list ul li").removeClass('selected');
    $("#xp_p1_list ul li").each(function(i, e){
      try {
        if ($(e).data('xp_data').dive_id == dive_id) {
          $(e).addClass('selected');
          panel1_zoom_to_selected();
        }
      } catch(ex) {}
    });

    $("#xp_p2h_head").text(dive.user.nickname+" @ "+dive.spot.name);
    $("#xp_p2h_head").data('xp_data', {'dive_id': dive_id});
    $('#xp_p2h_follow').hide();

    if (dive.featured_picture_medium) {
      $("#xp_p2_img").hide();
      initializeLayout();
      $("#xp_p2_img img").attr('src', dive.featured_picture_medium);
      $("#xp_p2_img img").load(function(){
        $("#xp_p2_img_container").css({'max-height':293});
        $("#xp_p2_img_fold").text('}');
        $("#xp_p2_img").show();
        initializeLayout();
      });
    } else {
      $("#xp_p2_img").hide();
    }
    $("#xp_p2_pages").html('');
    $("#xp_p2_pages").append(JST['explore/_xp2_dive']({dive:dive}));
    $("#xp_p2_pages img").load(initializeLayout);
    history_push( {'dive': dive} );

    $("#xp_p2_tabs .xp_panel_tab_link").removeClass('selected');
    $("#xp_p2_info_link").addClass('selected');
    $("#xp_panel_2 .xp_result_tab").hide();
    $("#xp_panel_2 #xp_p2_info_tab").show();
    show_panel2();//function(){center_if_not_visible(G_all_spots_mark[spot_id].getPosition())});

    center_if_not_visible(new google.maps.LatLng(dive.spot.lat, dive.spot.lng));
    for (var i in G_all_spots_mark) {
      G_all_spots_mark[i].setMap(null);
      delete G_all_spots_mark[i];
    }
    var marker = new ShopMarker(map, new google.maps.LatLng(dive.spot.lat, dive.spot.lng), '/img/explore/marker.png', dive.spot.name, "-12px", "-16px");
    marker.setZIndex(G_cluster_zindex_focus);
    G_all_spots_mark[dive.spot.id] = marker;
    make_marker_bounce(dive.spot);
    //TODO apply_highlight_spots(function(sid){return dive.spot.id==sid});

    update_perma_link(true);
  }

  if (dbx.dives[dive_id].pictures) {
    $("#xp_p2_pictures_tab").html("");
    $.each( dbx.dives[dive_id].pictures, function(i, pic) {
      console.log(pic);
      var im = $("<img/>").attr("src", pic.thumbnail);
      if (pic.permalink != "#")
        $("<a target='_blank'/>").attr('href', pic.permalink).append(im).appendTo("#xp_p2_pictures_tab");
      else
        im.appendTo("#xp_p2_pictures_tab");
    });
  }
  else {
    $("#xp_p2_pictures_tab").html("<div style='text-align: center; margin: 30px;'><img src='/img/transparent_loader_2.gif'/></div>");
  }
  initializeLayout();

  if (!completing){
    $("#xp_p2_like").hide();
    $("#xp_p2_info_link").show();
    $("#xp_p2_dives_link").hide();
    $("#xp_p2_divers_link").show();
    if (dive.featured_picture_medium) {
      $("#xp_p2_pictures_link").show();
    } else {
      $("#xp_p2_pictures_link").hide();
    }
  }
}

function show_shop_detail(shop_id)
{
  var shop = dbx.shops[shop_id];
  //Highlight the spot in the list
  $("#xp_p1_list ul li").removeClass('selected');
  $("#xp_p1_list ul li").each(function(i, e){
    try {
      if ($(e).data('xp_data').shop_id == shop_id) {
        $(e).addClass('selected');
        panel1_zoom_to_selected();
      }
    } catch(ex) {}
  });


  $("#xp_p2h_head").text(shop.name);
  $("#xp_p2h_head").data('xp_data', {'shop_id': shop_id});
  setup_follow_button('shop_id', shop_id);

  //Setting the image on panel 2
  $("#xp_p2_img").hide();
  initializeLayout();

  if (shop.logo_url.match(/diveboard\.com\/img\/no_picture\.png$/) == null)
    $("#xp_p2_img img").attr('src', shop.logo_url).load(function(){
      $("#xp_p2_img_container").css({'max-height':293});
      $("#xp_p2_img_fold").text('}');
      $("#xp_p2_img").show();
      initializeLayout();
    });

  //filling in the main form in panel 2
  $("#xp_p2_pages").html("");
  $("#xp_p2_pages").append(JST['explore/_xp2_shop']({shop:shop}));
  history_push( {'shop': shop} );

  //dbx.detail({'shops': [shop.id]}, (function(id){return function(){complete_spot_detail(id)}})(spot.id));

  $("#xp_p2_tabs .xp_panel_tab_link").removeClass('selected');
  $("#xp_p2_info_link").addClass('selected');
  show_panel2();//function(){center_if_not_visible(G_all_spots_mark[spot_id].getPosition())});
  $("#xp_panel_2 .xp_result_tab").hide();
  $("#xp_p2_info_tab").show();
  initializeLayout();

  $("#xp_p2_info_link").show();
  $("#xp_p2_like").hide();
  $("#xp_p2_divers_link").hide();
  $("#xp_p2_dives_link").hide();
  $("#xp_p2_pictures_link").hide();
  for (var i in shop.dives) {
    $("#xp_p2_dives_link").show();
    break;
  }
  //??? $("#xp_p2_img").hide();


  //Making sure the marker for the shop exists
  if (!shop.marker) {
    var result = add_marker_shop(shop);
    shop.marker = result.marker;
  }
  center_if_not_visible(shop.marker.getPosition());

  apply_highlight_shops(function(sid){return shop_id==sid});
  make_marker_bounce(shop);

  update_perma_link(true);
}

function show_loading_detail(){
  $("#xp_p2h_head").text(I18n.t(["js","explore","Loading..."]));
  $("#xp_p2h_head").data('xp_data', {});
  $('#xp_p2h_follow').hide();
  $("#xp_p2_img").hide();
  $("#xp_p2_pages").html("<div style='text-align: center; margin: 30px;'><img src='/img/transparent_loader_2.gif'/></div>");
  $("#xp_panel_2 .xp_result_tab").hide();
  $("#xp_p2_info_link").hide();
  $("#xp_p2_dives_link").hide();
  $("#xp_p2_divers_link").hide();
  $("#xp_p2_pictures_link").hide();
  $("#xp_p2_like").hide();
  show_panel2();
  initializeLayout();
}

///////////////////////
//
// BEST SPOT & DIVE FINDER OVERLAY
//
///////////////////////
//overlays are the best way to handle partial loading (by tiles) with google map


function BestDataOverlay(tileSize, obj) {
  this.tileSize = tileSize;
  this.contentClass = obj;
}

BestDataOverlay.prototype.getTile = function(coord, zoom, ownerDocument) {
  var div = ownerDocument.createElement('div');
  div.style.width = this.tileSize.width + 'px';
  div.style.height = this.tileSize.height + 'px';
  //div.style.border = "solid 1px red";
  //div.innerHTML = coord;
  //div.style.color = "red";
  div.className = "BestDataOverlayTile"
  div.clusters=[];

  var nb_tiles = Math.pow(2, zoom);
  var x = ((coord.x%nb_tiles) + nb_tiles)%nb_tiles;
  var y = ((coord.y%nb_tiles) + nb_tiles)%nb_tiles;

  div.className += " tile_"+zoom+'_'+x+'_'+y;

  $.ajax({
    'url': lbroot('/assets/explore/'+zoom+'/'+x+'_'+y+'.data.json?1'),
    'dataType': 'json',
    'success': function(data){
      div.DATA = data;
      //TODO: put the data in dbx
      dbx.feed(data);
      display_content();
    }
  });

  return div;
};

BestDataOverlay.prototype.releaseTile = function(div) {
  //this.contentClass.releaseTile(div);
  for (var i in div.clusters) {
    div.clusters[i].setMap(null);
  }
};

BestDataOverlay.prototype.localSpots = function(all){
  //Getting all the spots in the nearby
  var all_data=[];
  $(".BestDataOverlayTile").map(function(i,e){
    if (e.DATA && e.DATA.spots)
      all_data = all_data.concat( e.DATA.spots);
  });
  all_data = arrayGetUniqueById(all_data);

  //filtering to get only the visible spots
  var bounds = map.getBounds();
  var local_spots = [];
  for (var i in all_data) {
    var spot = all_data[i];
    var latlng = new google.maps.LatLng(spot.lat, spot.lng);
    if (bounds.contains(latlng)){
      local_spots.push(spot);
    }
  }

  //sorting by score, and returning the top spots only
  local_spots.sort(function(a,b){ if (a.score == b.score) return(0); return (a.score < b.score ? 1:-1); });

  //need to go through the store to get the latest detail if available
  if (all) return($.map( local_spots, function(e,i){return dbx.spots[e.id]}) );
  return($.map( local_spots.slice(0,25), function(e,i){return dbx.spots[e.id]}) );
}

BestDataOverlay.prototype.localDives = function(){
  //Getting all the dives in the nearby
  var all_data=[];
  var spots = {};
  $(".BestDataOverlayTile").map(function(i,e){
    if (e.DATA && e.DATA.spots)
      for (var i in e.DATA.spots) {
        var spot = e.DATA.spots[i];
        spots[spot.id] = spot;
      }
    if (e.DATA && e.DATA.dives)
      all_data = all_data.concat( e.DATA.dives);
  });
  all_data = arrayGetUniqueById(all_data);

  //filtering to get only the visible dives
  var bounds = map.getBounds();
  var local_dives = [];
  for (var i in all_data) {
    var dive = all_data[i];
    var spot = spots[dive.spot_id];
    var latlng = new google.maps.LatLng(spot.lat, spot.lng);
    if (bounds.contains(latlng)){
      local_dives.push(dive);
    }
  }

  //sorting by score, and returning the top dives only
  local_dives.sort(function(a,b){ if (a.score == b.score) return(0); return (a.score < b.score ? 1:-1); });

  //need to go through the store to get the latest detail if available
  return($.map( local_dives.slice(0,15), function(e,i){return dbx.dives[e.id]}) );
}

BestDataOverlay.prototype.localShops = function(){
 //Getting all the shops in the nearby
 var all_data=[];
  var shops = {};
  $(".BestDataOverlayTile").map(function(i,e){
    if (e.DATA && e.DATA.shops)
      for (var i in e.DATA.shops) {
        var shop = e.DATA.shops[i];
        shops[shop.id] = shop;
      }
    if (e.DATA && e.DATA.shops)
      all_data = all_data.concat( e.DATA.shops);
  });
  all_data = arrayGetUniqueById(all_data);

  //filtering to get only the visible dives
  var bounds = map.getBounds();
  var local_shops = [];
  for (var i in all_data) {
    var shop = all_data[i];
    if (shop.lat && shop.lng) {
      var latlng = new google.maps.LatLng(shop.lat, shop.lng);
      if (bounds.contains(latlng)){
        local_shops.push(shop);
      }
    }
  }

  //sorting by score, and returning the top shops only
  local_shops.sort(function(a,b){ if (a.score == b.score) return(0); return (a.score < b.score ? 1:-1); });

  //need to go through the store to get the latest detail if available
  return($.map( local_shops.slice(0,15), function(e,i){return dbx.shops[e.id]}) );
}


BestDataOverlay.prototype.localCountries = function(){
 //Getting all the dives in the nearby
 var all_data={};
  $(".BestDataOverlayTile").map(function(i,e){
    if (e.DATA && e.DATA.countries)
      for (var i in e.DATA.countries) {
        var country = e.DATA.countries[i];
        all_data[country.ccode] = country;
      }
  });

  delete all_data['BLANK']; //removing fake country

  var all_spots = this.localSpots(true);
  var local_countries = {};
  for (var i in all_spots)
    local_countries[all_spots[i].country_code] = all_data[all_spots[i].country_code];


  var list_data=[];
  for (var i in all_data)
    list_data.push(all_data[i]);

  //sorting by number of dives, and returning the top dives only
  list_data.sort(function(a,b){ if (a.dive_ids.length == b.dive_ids.length) return(0); return (a.dive_ids.length < b.dive_ids.length ? 1:-1); });

  //need to go through the store to get the latest detail if available
  return(list_data.slice(0,15) );
}


BestDataOverlay.prototype.localAdvertisements = function(){
  //Getting all the ads in the nearby
  var list_data=[];
  $(".BestDataOverlayTile").map(function(i,e){
    if (e.DATA && e.DATA.ads)
      for (var i in e.DATA.ads)
        list_data.push(e.DATA.ads[i]);

  });

  //Todo: sort list_data

  return(list_data.slice(0,3) );
}



///////////////////////
//
// CLUSTER OVERLAY
//
///////////////////////

diveboard.clusters = function() {
  var THIS = this;
  THIS.clusters = [];
  THIS.spot_clusters = {};
  THIS.current_highlight = null;
  var load_callbacks = [];
  var is_loading=null;

  this.load = function(zoom, callback){
    $.ajax({
      'url': lbroot('/assets/explore/clusters_'+zoom+'.json?1'),
      'dataType': 'json',
      'success': function(data){
        THIS.clusters[zoom] = data;
        THIS.index_spot_clusters(zoom);

        if (zoom == is_loading) {
          is_loading = null;
          for (var i in load_callbacks)
            load_callbacks[i].apply(THIS);
          load_callbacks = [];
        }

        THIS.highlight_clusters(THIS.current_highlight, zoom);
      }
    });
  };

  this.index_spot_clusters = function(zoom){
    for (var i in THIS.clusters[zoom]){
      var cluster = THIS.clusters[zoom][i];
      for (var j in cluster.spot_ids){
        var spot_id = cluster.spot_ids[j];
        if (!THIS.spot_clusters[spot_id]) THIS.spot_clusters[spot_id] = []
        THIS.spot_clusters[spot_id][zoom] = cluster.id;
      }
    }
  };

  this.clusters_from_spots = function(spot_list, zoom){
    var clusters = {};
    for (var i in spot_list) {
      var spot_id = spot_list[i];
      if (THIS.spot_clusters[spot_id] && THIS.spot_clusters[spot_id][zoom])
        clusters[ THIS.spot_clusters[spot_id][zoom] ] = true;
    }
    var ans = []
    for (var j in clusters)
      ans.push(j);

    return(ans);
  }

  this.highlight_clusters = function(spot_list, zoom) {
    THIS.current_highlight = spot_list;
    if (!spot_list) {
      THIS.cluster_list = null;
      $(".exploreCluster").removeClass("grey");
      return;
    }

    if (!THIS.current_highlight) {
      $(".exploreCluster").removeClass("grey");
      return;
    }
    THIS.cluster_list = THIS.clusters_from_spots(THIS.current_highlight, zoom);

    $(".exploreCluster").addClass("grey");
    $(".exploreCluster").each( function(i,e){
      var elt = $(e);
      var cluster = elt.data('cluster');
      if (!THIS.is_greyed(cluster))
          elt.removeClass("grey");
    });
  }

  this.is_greyed = function(cluster){
    if (!THIS.cluster_list)
      return(false);
    for (var j in THIS.cluster_list){
      if (cluster.id == THIS.cluster_list[j]){
        return(false);
      }
    }
    return(true);
  }

  //Loads the data if necessary before adding markers to the map
  this.drawTile = function(coord, zoom, tileSize, tile){
    if (THIS.clusters[zoom])
      this.drawTileLoaded(coord, zoom, tileSize, tile);
    else {
      if (is_loading == zoom) {
        load_callbacks.push(function(){this.drawTileLoaded(coord, zoom, tileSize, tile)});
      }
      else if (is_loading) {
        load_callbacks = [];
        load_callbacks.push(function(){this.drawTileLoaded(coord, zoom, tileSize, tile)});
        THIS.load(zoom);
      }
      else {
        load_callbacks.push(function(){this.drawTileLoaded(coord, zoom, tileSize, tile)});
        THIS.load(zoom);
      }
      is_loading = zoom;
    }
  };

  //Adds the required markers to the map
  this.drawTileLoaded = function(coord, zoom, tileSize, tile){
    //Check which markers should be displayed on that tile, and only display them
    var projection = map.getProjection();
    var numtiles = Math.pow(2, zoom);
    for (var idx in THIS.clusters[zoom]) {
      var cluster = THIS.clusters[zoom][idx];
      var point;
      point = projection.fromLatLngToPoint(new google.maps.LatLng(cluster.lat, cluster.lng));

      var x = Math.floor( point.x * numtiles / tileSize.width );
      var y = Math.floor( point.y * numtiles / tileSize.height );
      if ( (coord.x%numtiles+numtiles)%numtiles == x && (coord.y%numtiles+numtiles)%numtiles == y) { //coord can be negative or greater than numtiles
        var marker = add_marker_cluster(cluster);
        cluster.marker = marker;
        tile.clusters.push(marker);
        marker.setMap(map);
      }
    }
    THIS.highlight_clusters(THIS.current_highlight, zoom);
  };
};

diveboard.clusters.prototype = {
  'load': null,
  'clusters': null
};



function ClusterOverlay(tileSize, clusterer) {
  this.tileSize = tileSize;
  this.contentClass = clusterer;
}

ClusterOverlay.prototype.getTile = function(coord, zoom, ownerDocument) {
  var div = ownerDocument.createElement('div');
  div.style.width = this.tileSize.width + 'px';
  div.style.height = this.tileSize.height + 'px';
  //div.style.border = "solid 1px red";
  //div.innerHTML = coord;
  //div.style.color = "red";
  div.className = "ClusterOverlayTile"
  div.clusters=[];

  this.contentClass.drawTile(coord, zoom, this.tileSize, div);

  return div;
};

ClusterOverlay.prototype.releaseTile = function(div) {
  //this.contentClass.releaseTile(div);
  for (var i in div.clusters) {
    div.clusters[i].setMap(null);
  }
};





function ClusterLabel(opt_options) {
  // Initialization
  this.setValues(opt_options);

  // Label specific
  this.span_ = document.createElement('span');
  this.div_ = document.createElement('div');
  this.div_.appendChild(this.span_);
};

$(function(){
  // Define the overlay, derived from google.maps.OverlayView
  ClusterLabel.prototype = new google.maps.OverlayView;

  ClusterLabel.prototype.onAdd = function() {
    var pane = this.getPanes().overlayMouseTarget;
    pane.appendChild(this.div_);

    var me = this;
    this.listeners_ = [
      google.maps.event.addDomListener(this.span_, 'click', function(){
        if (me.cluster.count > 1){
          map.panTo(me.get('position'));
          map.setZoom(map.getZoom()+1);
        }
        else if (me.cluster.count == 1) {
          show_spot_detail(me.cluster.spot_ids[0]);
        }
      })
    ];
  };

  ClusterLabel.prototype.onRemove = function() {
    this.div_.parentNode.removeChild(this.div_);

    for (var i = 0, I = this.listeners_.length; i < I; ++i) {
      google.maps.event.removeListener(this.listeners_[i]);
    }
  };

  // Implement draw
  ClusterLabel.prototype.draw = function() {
    var latlng = this.get('position');
    var projection = this.getProjection();
    var position = projection.fromLatLngToDivPixel(latlng);

    this.div_.style.left = position.x + 'px';
    this.div_.style.top = position.y + 'px';
    this.div_.style.display = 'block';

    this.span_.innerHTML = this.get('text').toString();
    $(this.div_).data('cluster', this.get('cluster'));
    if (clusterer.is_greyed(this.get('cluster')))
      this.div_.className = this.get('clusterClass').toString()+" grey";
    else
      this.div_.className = this.get('clusterClass').toString();
  };
});

function add_marker_cluster(cluster) {
  var clusterClass = "exploreCluster ";
  if (cluster.count > 50) clusterClass += 'size4';
  else if (cluster.count > 20) clusterClass += 'size3';
  else if (cluster.count > 9) clusterClass += 'size2';
  else if (cluster.count > 1) clusterClass += 'size1';
  else clusterClass += 'size0';

  var marker = new ClusterLabel({
    text: cluster.count,
    'position': new google.maps.LatLng(cluster.lat, cluster.lng),
    clusterClass: clusterClass,
    cluster: cluster
  });

  return(marker);
}



///////////////////////
//
// MARKERS
//
///////////////////////


function add_marker_spot(spot) {
  // Add markers to the map
  var shape = {
      'coord': [1, 1, 1, 20, 18, 20, 18 , 1],
      'type': 'poly'
  };
  var marker = new google.maps.Marker({
      'position': new google.maps.LatLng(spot.lat, spot.lng),
      //map: map,
      'shadow': marker_shadow,
      'icon': marker_highlight,
      'shape': shape,
      'title': spot.name,
      'zIndex': G_cluster_zindex_highlight
  });

  google.maps.event.addListener(marker, 'click', function(){ show_spot_detail(spot.id); });

  return(marker);
}

function add_marker_shop(shop) {
  var marker;
  if (!G_current_highlight_shop_filter || G_current_highlight_shop_filter.apply(this, [shop.id, shop]) )
    marker = new ShopMarker(map, new google.maps.LatLng(shop.lat, shop.lng), '/img/explore/marker_shop.png', shop.name);
  else
    marker = new ShopMarker(map, new google.maps.LatLng(shop.lat, shop.lng), '/img/explore/marker_shop_grey.png', shop.name);
  marker.setMap(map);
  google.maps.event.addListener(marker, 'click', function(){ show_shop_detail(shop.id); });
  return({'marker': marker});
}




function apply_highlight_spots(spot_list)
{
  if (diveboard.postpone_me(100)) return;
  clusterer.highlight_clusters(spot_list, map.getZoom());
}

function apply_highlight_shops(filter)
{
  //apply_highlight_spots();

  if (diveboard.postpone_me(100)) return;

  G_current_highlight_shop_filter = filter;

  if (typeof filter == 'undefined' || filter == null) {
    G_current_highlight_shop_filter = null;
    filter = function(){return true};
  }

  $.each( dbx.shops, function(shop_id, shop) {
    if (shop.marker && filter.apply(this, [shop_id, shop]))
    {
      shop.marker.setIcon(marker_shop_highlight);
      shop.marker.setZIndex(G_cluster_zindex_highlight+1);
      shop.marker.show();
    }
    else if (shop.marker)
    {
      shop.marker.setIcon(marker_shop_lowlight);
      shop.marker.setZIndex(G_cluster_zindex_lowlight+1);
      if (map.getZoom() < G_min_zoom_shops)
        shop.marker.hide();
    }
  });
}


function make_marker_bounce(obj)
{
  var marker;
  if (obj.marker)
    marker = obj.marker;
  else
    marker = G_all_spots_mark[obj.id];
  if (marker && marker.getAnimation() == null){
    var previous_map = marker.getMap();
    if (!previous_map) marker.setMap(map);
    marker.setZIndex(99999);
    marker.setAnimation(google.maps.Animation.BOUNCE);
    setTimeout(function(){ if (!marker.getMap()) marker.setMap(map); }, 1000);
    setTimeout(function(){
        //var marker = G_all_spots_mark[1721];
        marker.setAnimation(null);
        if (!previous_map) marker.setMap(null);
        apply_highlight_shops(G_current_highlight_shop_filter);
     }, 5000); //TODO:perf: be more specific about when it's needed to highlight shops
  }
}



function ShopMarker(map, position, image, name, offset_x, offset_y) {
  this.map_ = map;
  this.image_ = image;
  this.position_ = position;
  this.name_ = name;
  this.div_ = null;
  this.bouncy_ = false;
  this.zIndex_ = 0;
  this.offset_x = offset_x||0;
  this.offset_y = offset_y||0;
  this.setMap(map);
}

function define_shopmarker() {
  ShopMarker.prototype.onAdd = function() {

    // Create an IMG element and attach it to the DIV.
    var img = document.createElement("img");
    img.src = this.image_;
    if (this.name_)
      img.title = this.name_;
    img.style.position = 'absolute';
    img.style.left = this.offset_x;
    img.style.top = this.offset_y;
    img.style.cursor = 'pointer';
    this.div_ = document.createElement("div");
    this.div_.style.position = 'absolute';
    this.div_.appendChild(img);

    // We add an overlay to a map via one of the map's panes.
    // We'll add this overlay to the overlayImage pane.
    var panes = this.getPanes();
    panes.overlayMouseTarget.appendChild(this.div_);

    var me=this;
    google.maps.event.addDomListener(img, 'click', function() {
      google.maps.event.trigger(me, 'click');
    });
  }

  ShopMarker.prototype.draw = function() {
    if (!this.div_) return;
    var div = this.div_;
    var overlayProjection = this.getProjection();
    var pos = overlayProjection.fromLatLngToDivPixel(this.position_);
    div.style.left = pos.x + 'px';
    div.style.top = pos.y + 'px';
    div.style.zIndex = this.zIndex_;
    $(this.div_).stop();
    div_jump(this);
  }

  ShopMarker.prototype.onRemove = function() {
    this.div_.parentNode.removeChild(this.div_);
    this.div_ = null;
  }

  ShopMarker.prototype.hide = function() {
    if (this.div_) {
      this.div_.style.visibility = "hidden";
    }
  }

  ShopMarker.prototype.show = function() {
    if (this.div_) {
      this.div_.style.visibility = "visible";
    }
  }

  ShopMarker.prototype.setImage = function(image) {
    this.div_.src = image;
    this.image_ = image;
    this.draw();
  }
  ShopMarker.prototype.setIcon = function(icon) {
    if (this.div_) {
      this.setImage(icon.url);
    }
  }
  ShopMarker.prototype.setZIndex = function(index) {
    this.zIndex_ = index;
    this.draw();
  }
  ShopMarker.prototype.setAnimation = function(animation) {
    this.bouncy_ = (animation!=null);
    this.animation_ = animation;
    this.draw();
  }
  ShopMarker.prototype.getAnimation = function() {
    return(this.animation_);
  }
  ShopMarker.prototype.getPosition = function() {
    return this.position_;
  }
}

function div_jump(marker) {
  if (marker == null) {
    if (console && console.log) console.log('marker is null');
    return;
  }
  if (!marker.bouncy_) return;
  if (marker.div_ == null) {
    if (console && console.log) console.log('marker.div_ is null');
    return;
  }
  var top = parseInt(marker.div_.style.top);
  $(marker.div_).animate({top: (top-10)},500).animate({top: (top)},300, function(){div_jump(marker)});
}


///////////////////////
//
//  MAP MANIPULATION
//
///////////////////////

function get_covered_lng_extent()
{
  var canvas = $("#map_canvas");
  var proj = map_overlay.getProjection();
  var a=new google.maps.LatLng(0, 0),
      b=new google.maps.LatLng(0, 1);

  return canvas.width() / ( proj.fromLatLngToContainerPixel( b ).x-proj.fromLatLngToContainerPixel( a ).x );
}

function get_covered_bounds()
{
  var min_lat, min_lng, max_lat, max_lng;

  var canvas = $("#map_canvas");
  var proj = map_overlay.getProjection();
  var top = proj.fromContainerPixelToLatLng({x:0, y:0}),
      bottom = proj.fromContainerPixelToLatLng({x:0, y:canvas.height()});
  var lng_width = get_covered_lng_extent();

  if (lng_width > 360) {
    min_lng = -180;
    max_lng = 180;
  }
  else {
    min_lng = top.lng();
    max_lng = (min_lng + lng_width + 180)%360 - 180;
  }


  min_lat = bottom.lat();
  max_lat = top.lat();

  return {sw:{lat:min_lat,lng:min_lng}, ne:{lat:max_lat,lng:max_lng}};
}

function is_within_bounds(point, bounds) {
  //easy try on latitudes
  if (point.lat < bounds.sw.lat || point.lat > bounds.ne.lat)
    return false;

  //usual case
  if (bounds.sw.lng < bounds.ne.lng) {
    return (point.lng >= bounds.sw.lng && point.lng <= bounds.ne.lng)
  }
  //over the pacific
  else {
    return (point.lng >= bounds.sw.lng || point.lng <= bounds.ne.lng)
  }
}


function is_visible(latLng) {
  var canvas = $("#map_canvas");
  var proj = map_overlay.getProjection();

  var position = proj.fromLatLngToContainerPixel(latLng);

  if ( position.y < 20 )
    return false;

  if ($("#xp_panel_2").is(":visible"))
    return (position.x > $("#xp_panel_2").width() && position.x < canvas.width());
  else
    return (position.x > 0 && position.x < canvas.width());
}

function center_if_not_visible(latLng)
{
  if (!is_visible(latLng)) {
    map.setCenter(latLng);
    //display_content();
  }

  update_perma_link();
}

function pan_if_not_visible(latLng)
{
  if (!map.getBounds().contains(latLng)){
    var dx=0, dy=0;
    var proj = map.getProjection();
    var bounds = map.getBounds();
    var p = proj.fromLatLngToPoint(latLng);
    var ne = proj.fromLatLngToPoint(bounds.getNorthEast());
    var sw = proj.fromLatLngToPoint(bounds.getSouthWest());
    var c = proj.fromLatLngToPoint(map.getCenter());

    if (p.x > ne.x) dx = p.x-ne.x;
    else if (p.x < sw.x) dx = sw.x-p.x;

    if (p.y < ne.y) dy = p.y-ne.y;
    else if(p.y > sw.y) dy = sw.y-p.y;

    c.x -= dx;
    c.y -= dy;
    map.setCenter(proj.fromPointToLatLng(c));
  }
  update_perma_link();
}

function crop_left(crop_dx, callback)
{
  var proj = map.getProjection();
  var ww = proj.fromLatLngToPoint(proj.fromPointToLatLng({'x':-0.1, 'y':0})).x+.1; //world width
  var wx = $("#map_canvas").width();
  var c = proj.fromLatLngToPoint(map.getCenter());
  var bounds = map.getBounds();
  var ne = proj.fromLatLngToPoint(bounds.getNorthEast());
  var sw = proj.fromLatLngToPoint(bounds.getSouthWest());
  if (ne.x>sw.x)
    c.x += 1.0*(crop_dx+wx-995)*(ne.x-sw.x)/wx;
  else
    c.x += 1.0*(crop_dx+wx-995)*(ww+ne.x-sw.x)/wx;

  var qwertgsfd = google.maps.event.addListener(map,'bounds_changed',function (event) {
    google.maps.event.removeListener(qwertgsfd);
    $("#map_canvas").css('width', 995-crop_dx);
    google.maps.event.trigger(map, 'resize');
    if (typeof callback == 'function') callback.apply(this, []);
  });
  map.setCenter(proj.fromPointToLatLng(c));
}

function show_panel2(callback)
{
  if ($("#xp_panel_2").is(':visible')) return;
  //crop_left(300, callback);
  $("#xp_panel_2").show();
  $("#xp_panel_2").attr('clicked',true);
  if($(window).width()<730){
    $("#xp_panel_1").hide();

    $("#xp_panel_2").css('left','0px');
    $("#xp_p2h_icon").css('font-size','30px');

    $("#xp_p2h_icon").css('z-index','10');

    $("#xp_p2h_icon").css('right','50px');
    $('.text_follow').remove();

  }
  update_perma_link();
  update_map_width();
  //display_content();
}

function hide_panel2(callback)
{
  history_clear();
  if (!$("#xp_panel_2").is(':visible')) return;
  //crop_left(0, callback);
  $("#xp_panel_2").hide();
  $("#xp_panel_2").attr('clicked',false);

  for (var i in G_all_spots_mark) {
    G_all_spots_mark[i].setMap(null);
    delete G_all_spots_mark[i];
  }
  setTimeout(function(){apply_highlight_spots(null)}, 100);
  update_perma_link();
  update_map_width();
  $("#xp_p2_like").hide();
  window.history.pushState("", "", "/explore");
  //display_content();
}
function update_map_width(){

  //$("#map_canvas").css('width', $(window).width()-$("#xp_panel_1").width() - 2+"px");
  var width = $(window).width()-$("#xp_panel_1").width() + 7;
  try{
    var center = map.getCenter();
  }catch(e){}

  if ($("#xp_panel_2").is(":visible"))
    width = width - $("#xp_panel_2").width();

  $("#map_canvas").css('width', width+"px");
  try{
    resizeMap(map, center); //tell google he's been fucked
  }catch(e){}
}

function resizeMap(m, c) {
    google.maps.event.trigger(m, 'resize');
    m.setCenter(c);
};


function update_perma_link(publish_analytics)
{
  //PMA TODO
  var center = map.getCenter()
  var base_url = G_locale_root_url + "explore";
  var args = "lat="+center.lat()+"&lng="+center.lng()+"&zoom="+map.getZoom();//+"&tab="+selected_tab;
  /*
  if (selected_tab == "spot")
  {
  }
  else if (selected_tab == "diver")
  {
    url += "&diver="+selected_diver;
  }
  else if (selected_tab == "search")
  {
    url += "&type="+$("#js_dd_selected").text();
    url += "&what="+escape($("#search_text_field").val());
    if (selected_diver)
      url += "&diver="+selected_diver;
    if (selected_place)
      url += "&place="+escape(selected_place);
    if (selected_spot)
      url += "&spot_id="+escape(selected_spot);
  }
  //todo handle infowindow if open
  */
  $("#permalink").val(base_url+args);

  //if (typeof publish_analytics != 'undefined' && publish_analytics)
  //  ga('send', 'pageview', base_url);
}


function goto_search_result(result) {
  var lat = result.geometry.location.lat;
  var lng = result.geometry.location.lng;
  map.fitBounds(result.geometry.viewport);
  //display_content();
  update_perma_link();
}

function zoom_on_user(user_id){
  user = dbx.users[user_id];
  var dive_count = 0;
  var bounds = null
  for (var i in user.dives) {
    var spot = user.dives[i].spot;
    var spot_pos = new google.maps.LatLng( spot.lat, spot.lng);
    if (bounds == null)
      bounds = new google.maps.LatLngBounds(spot_pos, spot_pos);
    else
      bounds.extend(spot_pos);
  }

  map.fitBounds(bounds);
}

//////////////////////////
//
// SEARCH
//
//////////////////////////

function search_something(text) {
  if (text == '') {
    $("#xp_p1_search_result ul").html('');
    $("#xp_p1_search_result").hide();
    return;
  }

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

          initializeLayout();

        } else {
          //alert("Geocode was not successful for the following reason: " + status);
        }
      }
    );
}

//////////////////////////
//
// ADVERTISEMENTS
//
//////////////////////////

function append_ads_if_empty(){
  if ($('.ad_item').length == 0)
    cycle_ads();
}

function append_ads(){
  var ad_container = $("#ad_container");
  if (ad_container.length == 0) {
    ad_container = $("<div id='ad_container' style='display:none;'></div>");
    map.controls[google.maps.ControlPosition.TOP_LEFT].push(ad_container[0]);
  }

  var ads = best_data_overlay.localAdvertisements();
  var current_ads = [];
  $('.ad_item').each(function(i,e){
    current_ads[$(e).data('ad').id] = 'present';
  });

  for (var i in ads) {
    var ad = ads[i];
    if (current_ads[ad.id]) {
      current_ads[ad.id] = 'keep';
    }
    else {
      var item = $(JST['ads/_explore_advertisement'](ad));
      item.data('ad', ad);
      ad_container.append(item);
    }
  }

  $('.ad_item').each(function(i,e){
    if (current_ads[$(e).data('ad').id] == 'present')
      $(e).detach();
  });
}

function cycle_ads(){
  append_ads();

  var ads = $('.ad_item');
  if (ads.length > 0) {
    var current_ad = $('.ad_item.selected');
    var ad_data = current_ad.data('ad');
    var current_ad_index = ads.index(current_ad);
    ads.removeClass('selected').hide();
    $("#ad_container").show();
    $(ads[(current_ad_index+1) % ads.length]).addClass('selected').show();
    if (typeof ad_data != 'undefined')
      $.ajax({url: "/api/stats_trace/ad_explore/"+ad_data.id+"/print"});
  }
  else
    $("#ad_container").hide();
}


//////////////////////////
//
// FOLLOW
//
//////////////////////////

function setup_follow_button(what, id)
{
  try {
    //if user is not logged in, then he cannot follow anything...
    if (!G_user_id) {
      $('#xp_p2h_follow .text_waiting').hide();
      return;
    }

    $('#xp_p2h_follow .text_follow, #xp_p2h_follow .text_unfollow').hide();
    $('#xp_p2h_follow .text_waiting').show();
    $('#xp_p2h_follow').show();

    $('#xp_p2h_follow>a').attr('data-db-follow-what', what);
    $('#xp_p2h_follow>a').attr('data-db-follow-id', id);
    $.ajax({
      url: '/api/user/following?'+what+'='+id,
      type:'GET',
      success: function(data){
        if (data.success) {
          if (data.following) {
            $('#xp_p2h_follow .text_waiting').hide();
            $('#xp_p2h_follow .text_unfollow').show();
          } else {
            $('#xp_p2h_follow .text_waiting').hide();
            $('#xp_p2h_follow .text_follow').show();
          }
        }
        else {
          $('#xp_p2h_follow').hide();
        }
      },
      error: function(){
        $('#xp_p2h_follow').hide();
      }
    })
  } catch(e) {
    if (console && console.log)
      console.log(e);
    $('#xp_p2h_follow').hide();
  }
}

//////////////////////////
//
// DATA
//
//////////////////////////


diveboard.dbxplore = function(params){
  var store = {
    spots: {},
    users: {},
    dives: {},
    countries: {},
    regions: {},
    locations: {},
    pictures:{},
    shops:{},
    ads:{}
  };
  var index = [];
  var index_shops = [];
  var data_ready = false;

  this.ready = function(){ return(data_ready) };

  var extend_var = function(dst, src){
    $.each(src, function(id,val){
      if (!dst[id] || id == 'flavour')
        dst[id] = val;
      else if (typeof src == 'object' && typeof dst[id] == 'object')
        extend_var(dst[id], val);
    });
  };

  var link_all = function(){

    var modele = {
      countries: [
        {ids: 'dive_ids', objs: 'dives', type: 'dives'}
      ],
      locations: [
        {ids: 'dive_ids', objs: 'dives', type: 'dives'}
      ],
      regions: [
        {ids: 'dive_ids', objs: 'dives', type: 'dives'}
      ],
      spots: [
        {ids: 'dive_ids', objs: 'dives', type: 'dives'},
        {ids: 'user_ids', objs: 'users', type: 'users'},
        {ids: 'shop_ids', objs: 'shops', type: 'shops'},
        {ids: 'picture_ids', objs: 'pictures', type: 'pictures'}
      ],
      users: [
        {ids: 'public_dive_ids', objs: 'dives', type: 'dives'},
        {ids: 'spot_ids', objs: 'spots', type: 'spots'},
        {ids: 'dive_picture_ids', objs: 'dive_pictures', type: 'pictures'}
      ],
      dives: [
        {ids: 'user_id', objs: 'user', type: 'users'},
        {ids: 'spot_id', objs: 'spot', type: 'spots'},
        {ids: 'db_buddy_ids', objs: 'db_buddies', type: 'users'},
        {ids: 'picture_ids', objs: 'pictures', type: 'pictures'}
      ],
      shops: [
        {ids: 'dive_ids', objs: 'dives', type: 'dives'}
      ],
      ads: []
    }


    for (var klasse in modele) {
      for (var c_i in modele[klasse]) {
        var param = modele[klasse][c_i];

        for (target_id in store[klasse]){
          var target = store[klasse][target_id]
          var dest_type;
          if (param.ids in target && typeof target[param.ids] == 'number')
            dest_type = 'link';
          else if (param.ids in target && typeof target[param.ids].length == 'number')
            dest_type = 'array';
          else
            dest_type = 'hash';

          if (dest_type == 'link')
            target[param.objs] = store[param.type][target[param.ids]];
          else {

            //initialize the destination
            if (!(param.objs in target) && param.ids in target)
              if (dest_type == 'array')
                target[param.objs] = new Array;
              else
                target[param.objs] = {};

            //Process every element
            for (var idx in target[param.ids]) {
              var id = parseInt(target[param.ids][idx]);
              if (typeof id == 'number' && id in store[param.type]) {
                if (dest_type == 'array')
                  target[param.objs][idx] = store[param.type][id];
                else
                  target[param.objs][id] = store[param.type][id];
              }
            }
          }
        }

      }
    }


  };


  this.feed = function(data){
    var local_this = this;


    var keys = ['dives', 'users', 'spots', 'shops', 'countries', 'regions'];

    for (var j in keys) {
      var key = keys[j];
      if (data && data[key])
        for (var i in data[key])
          if (!store[key][data[key][i].id])
            store[key][data[key][i].id] = data[key][i];
    }



    link_all();
    local_this.build_index();
  };

  this.detail = function(request, callback) {
    var local_this=this;

    //Do not request objects that we already have
    var objects_needed = {};
    for (var cat in request) {
      try {
        for (var i in request[cat])
          try {
            var id = request[cat][i];
            if (this[cat][id].flavour != 'search_full')
              objects_needed[cat].push(id);
          } catch(e) {
            objects_needed[cat].push(id);
          }
      } catch(e){
        objects_needed[cat] = request[cat];
      }
    }
    $.ajax({
      'url': "/api/explore/detail",
      'data': request,
      'dataType': 'json',
      'success': function(data, textStatus, jqXHR){
        if (!data.success) return;
        extend_var(store, data.result);
        link_all();
        //local_this.build_index();
        if (callback) callback(data);
      }
    });
  }

  var offset = function(lat,lng) {
    return((90+Math.floor(lat))*360+180+Math.floor(lng));
  };

  this.build_index = function(){
    //index = [];
    for (spot_id in store.spots) {
      var spot = store.spots[spot_id];
      var o = offset(spot.lat, spot.lng);
      if (typeof index[o] == 'undefined')
        index[o] = [spot];
      else
        index[o].push(spot);
    }

    for (shop_id in store.shops) {
      var shop = store.shops[shop_id];
      var o = offset(shop.lat, shop.lng);
      if (typeof index_shops[o] == 'undefined')
        index_shops[o] = [shop];
      else
        index_shops[o].push(shop);
    }

    data_ready = true;
    if (typeof params.onDataReady === 'function') params.onDataReady.apply(this, []);
  };

  var sort_uniqueID = function(arr) {
    if (typeof arr[0] == 'undefined') return [];
    arr = arr.sort(function (a, b) { return a.id*1 - b.id*1; });
    var ret = [arr[0]];
    for (var i = 1; i < arr.length; i++) { // start loop at 1 as element 0 can never be a duplicate
        if (arr[i-1].id !== arr[i].id) {
            ret.push(arr[i]);
        }
    }
    return ret;
  };

  this.shops_in = function(bounds){
    var all = [];

    for (var lat = Math.floor(bounds.sw.lat); lat <= bounds.ne.lat; lat++){
      if (bounds.sw.lng < bounds.ne.lng) {
        for (var lng = Math.floor(bounds.sw.lng); lng <= bounds.ne.lng; lng++) {
          //searching quickly through the index, then refining the result set
          var indexed_result = index_shops[offset(lat, lng)]
          for (var i in  indexed_result)
            if (bounds.sw.lat <= indexed_result[i].lat && indexed_result[i].lat <= bounds.ne.lat && bounds.sw.lng <= indexed_result[i].lng && indexed_result[i].lng <= bounds.ne.lng )
              all.push(indexed_result[i]);
        }
      }
      else {
        for (var lng = Math.floor(bounds.sw.lng); lng <= 180; lng++) {
          //searching quickly through the index, then refining the result set
          var indexed_result = index_shops[offset(lat, lng)]
          for (var i in  indexed_result)
            if (bounds.sw.lat <= indexed_result[i].lat && indexed_result[i].lat <= bounds.ne.lat && bounds.sw.lng <= indexed_result[i].lng )
              all.push(indexed_result[i]);
        }
        for (var lng = -180; lng <= bounds.ne.lng; lng++) {
          //searching quickly through the index, then refining the result set
          var indexed_result = index_shops[offset(lat, lng)]
          for (var i in  indexed_result)
            if (bounds.sw.lat <= indexed_result[i].lat && indexed_result[i].lat <= bounds.ne.lat && indexed_result[i].lng <= bounds.ne.lng )
              all.push(indexed_result[i]);
        }
      }
    }

    //no need here to sort_uniqueID
    return(all);
  };



  //for debug and more
  this.spots = store.spots;
  this.users = store.users;
  this.dives = store.dives;
  this.regions = store.regions;
  this.locations = store.locations;
  this.countries = store.countries;
  this.shops = store.shops;


};

diveboard.dbxplore.prototype = {
  'feed': null,
  'build_index': null,
  'ready': function(){return(false)}
};





////////////////////////
//
// HELPERS
//
////////////////////////

function isHashEmpty(h)
{
  for (var i in h) return(false);
  return(true);
}

function valuesOfHash(h)
{
  var vals = [];
  for (var i in h)
    vals.push(h[i]);
  return(vals);
}

function sort_keys_by_value_desc(h)
{
  var keys = [];
  for (var k in h)keys.push(k);
  return keys.sort(function(a,b){return h[b]-h[a];});
}

function location_string_of_spot(spot)
{
  var location_string = '';
  if (spot.location) location_string += spot.location;
  if (spot.region && location_string != '') location_string += ', ';
  if (spot.region) location_string += spot.region;
  if (spot.country && location_string != '') location_string += ', ';
  if (spot.country) location_string += spot.country;
  return(location_string);
}

function sort_dive_by_score(divelist) {
  function dive_score(dive) {
    var score = 0;
    if (dive.featured_picture_medium) score += 15;
    if (dive.favorite) score += 6;
    if (dive.notes) score += 5;
    if (dive.diveshop) score += 3;
    if (dive.db_buddies) score += 3;
    if (!dive.spot || dive.spot.name == "") score -= 5;
    if (dive.max_depth == 0) score -= 2;
    return(score);
  };

  return divelist.sort(function(a,b){
    var sa=dive_score(a);
    var sb=dive_score(b);
    if (sa==sb && a.date == b.date) return 0;
    if (sa==sb) return a.date < b.date?1:-1;
    return sa<sb?1:-1;
  });
}

function sort_shop_by_score(shoplist) {
  function shop_score(shop) {
    var score = 0;
    score += shop.dive_ids.length;
    if (shop.logo_url) score += 5;
    return(score);
  };

  return shoplist.sort(function(a,b){
    var sa=shop_score(a);
    var sb=shop_score(b);
    if (sa==sb && a.name == b.name) return 0;
    if (sa==sb) return a.name > b.name?1:-1;
    return sa<sb?1:-1;
  });
}




function wiki_edit_popup(ev){
  if(ev)
      ev.preventDefault();

  if($(".xp_p2_info_tab_wiki").hasClass("haswiki"))
    var wiki_text =  $(".xp_p2_info_tab_wiki").html();
  else
    var wiki_text = null;

  edit_wiki(
    $(".xp_p2_info_tab_wiki").attr("obj_id"),
    $(".xp_p2_info_tab_wiki").attr("obj_type"),
    wiki_text ,
    function(new_text){
      $(".xp_p2_info_tab_wiki").html(new_text);
      if($(".xp_p2_info_tab_wiki").attr("obj_type").match(/Country/i)){
        dbx.countries[$(".xp_p2_info_tab_wiki").attr("obj_id")].wiki_html = new_text;
      }else if($(".xp_p2_info_tab_wiki").attr("obj_type").match(/Location/i)){
        dbx.locations[$(".xp_p2_info_tab_wiki").attr("obj_id")].wiki_html = new_text;
      }else if($(".xp_p2_info_tab_wiki").attr("obj_type").match(/Region/i)){
        dbx.regions[$(".xp_p2_info_tab_wiki").attr("obj_id")].wiki_html = new_text;
      }else if($(".xp_p2_info_tab_wiki").attr("obj_type").match(/Spot/i)){
        dbx.spots[$(".xp_p2_info_tab_wiki").attr("obj_id")].wiki_html = new_text;
      }
      if(new_text == "" || new_text == null){
        $(".xp_p2_info_tab_wiki").removeClass("haswiki");
        $(".xp_p2_info_tab_wiki_edit").hide();
        $(".xp_wiki_contribute").show();
      }else{
        $(".xp_p2_info_tab_wiki").addClass("haswiki");
        $(".xp_p2_info_tab_wiki_edit").show();
        $(".xp_wiki_contribute").hide();
      }
    }
  );
}

function lbroot(s){
  if (!s)
    return(G_balanced_roots[Math.floor(Math.random()*G_balanced_roots.length)]);
  else{
    return(G_balanced_roots[s.hashCode(G_balanced_roots.length)]+ s);
  }
}

String.prototype.hashCode = function(M){
    var hash = 0;
    if (this.length == 0) return hash;
    for (i = 0; i < this.length; i++) {
        ch = this.charCodeAt(i);
        hash = ((hash<<5)-hash)+ch;
        hash = hash & hash; // Convert to 32bit integer
    }
    return((M+hash%M)%M);
}


/*
 [
    { 'url': "/img/explore/m1.png", 'width': 53, 'height': 53 },
    { 'url': "/img/explore/m2.png", 'width': 56, 'height': 56 },
    { 'url': "/img/explore/m3.png", 'width': 66, 'height': 66 },
    { 'url': "/img/explore/m4.png", 'width': 78, 'height': 78 },
    { 'url': "/img/explore/m5.png", 'width': 90, 'height': 90 },
    { 'url': "/img/explore/m6.png", 'width': 53, 'height': 53 },
    { 'url': "/img/explore/m7.png", 'width': 56, 'height': 56 },
    { 'url': "/img/explore/m8.png", 'width': 66, 'height': 66 },
    { 'url': "/img/explore/m9.png", 'width': 78, 'height': 78 },
    { 'url': "/img/explore/m10.png", 'width': 90, 'height': 90 }
  ];
  */

function mark_to_stars(mark){
  var l = [];
  var threshold = 0.8;
  for (var i = 0; i < 10; i++){
    var star = "half_star ";
    if (i+threshold <= mark*2) star += "on ";
    else star += "off ";
    if (i%2 == 0) star += "left";
    else star += "right";
    l.push(star);
  }
  return(l);
};

arrayGetUniqueById = function(arr){
   var u = {}, a = [];
   for(var i = 0, l = arr.length; i < l; ++i){
      if(u.hasOwnProperty(arr[i].id)) {
         continue;
      }
      a.push(arr[i]);
      u[arr[i].id] = 1;
   }
   return a;
}