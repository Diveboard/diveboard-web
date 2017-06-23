// Marker sizes are expressed as a Size of X,Y
// where the origin of the image (0,0) is located
// in the top left of the image.

// Origins, anchor positions and coordinates of the marker
// increase in the X direction to the right and in
// the Y direction down.
var G_marker_image = new google.maps.MarkerImage('/img/marker.png',
    // This marker is 20 pixels wide by 32 pixels tall.
    new google.maps.Size(19, 23),
    // The origin for this image is 0,0.
    new google.maps.Point(0,0),
    // The anchor for this image is the base of the flagpole at 0,23.
    new google.maps.Point(5, 28));
var G_marker_shadow = new google.maps.MarkerImage('/img/mark_shadow.png',
    // The shadow image is larger in the horizontal dimension
    // while the position and offset are the same as for the main image.
    new google.maps.Size(19, 23),
    new google.maps.Point(0,0),
    new google.maps.Point(0, 23));
    // Shapes define the clickable region of the icon.
    // The type defines an HTML <area> element 'poly' which
    // traces out a polygon as a series of X,Y points. The final
    // coordinate closes the poly by connecting to the first
    // coordinate.
var G_marker_shape = {
    coord: [1, 1, 1, 20, 18, 20, 18 , 1],
    type: 'poly'
};
var G_markerCluster;




function country_page_initialize()
{
  //
  // Bindings
  //



  //
  // Map initialisation
  //
  var latlngbnds = new google.maps.LatLngBounds();

  var all_markers = [];
  for (i=0; i < G_user_spots_data.length; i++)
  {
    var latLng = new google.maps.LatLng(G_user_spots_data[i].lat, G_user_spots_data[i].lng);
    latlngbnds.extend(latLng);
    var mark = new google.maps.Marker({
        position: latLng,
        //map: map,
        shadow: G_marker_shadow,
        icon: G_marker_image,
        shape: G_marker_shape,
        //title: "todo title",
        zIndex: 10
      });
    all_markers.push(mark);
  }


  var latlng;
  if (G_user_spots_data.length > 0)
    latlng = latlngbnds.getCenter();
  else
    latlng = new google.maps.LatLng(15, 0);
  var myOptions = {
    zoom: 13,
    maxZoom: 17,
	minZoom:1,
    center: latlng,
    streetViewControl: false,
    mapTypeId: google.maps.MapTypeId.HYBRID
  };
  map = new google.maps.Map(document.getElementById("spot_map_container"), myOptions);

  if (G_user_spots_data.length > 0)
  {
	map.fitBounds(latlngbnds);
	
    zoomChangeBoundsListener = google.maps.event.addListener(map,'bounds_changed',function (event) {
        google.maps.event.removeListener(zoomChangeBoundsListener);
        if (map.getZoom()>G_zoom_level) map.setZoom(G_zoom_level);
      });

  }
  //Setting up the clusterer
  G_markerCluster = new MarkerClusterer(map, []);
  G_markerCluster.setGridSize(45);
  G_markerCluster.setMaxZoom(G_zoom_level);
  G_markerCluster.addMarkers(all_markers);
	if (G_user_spots_data.length > 0)
		map.fitBounds(latlngbnds);

  //
  // Google plus one
  //
  diveboard.plusone_go();

  //
  // Share button
  //
  share_initialize();

try {
    $(".spot_wiki_data").jScrollPane({showArrows: false, hideFocus:true});
  } catch(e) {}



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
		
	
	//Stats menu bindings
	$(".spot_data_menu a").click(function(ev){
		ev.preventDefault();
		$(".spot_data_menu a").removeClass("spot_menu_selected");
		$(this).addClass("spot_menu_selected");
		id = $(this).attr("id").split("_")[1]
		$(".spot_data_content_stats").hide()
		$("#content_"+id).show();
		}
	);
		
		
		
}

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

