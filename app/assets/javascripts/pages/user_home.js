// Marker sizes are expressed as a Size of X,Y
// where the origin of the image (0,0) is located
// in the top left of the image.

var G_marker_image;
var G_marker_shadow;
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

var G_edit_mode = false; //by default, we're not editing



function logbook_user_home_initialize()
{
  //
  // Bindings
  //

  $(".edit_link").click(switch_to_edit_mode);
  $(".userhome_save").click(save_edit_mode);
  $(".userhome_cancel").click(cancel_edit_mode);

 $(".tab_link").live('click', function(e) {
    if (e) e.preventDefault();
    $(".tab_panel").hide();
    var link = $(this);
    var tab_name = link.attr('id').replace(/_link$/,'');
    if(G_edit_mode){
      tab_name += "_edit"; // if in edit mode we load edit tab
      if ($("."+tab_name).length == 0){
        tab_name = "tab_info_edit"; //fallback as the info tab
        link = $("#tab_info_link")
      }
    }else{
      if ($("."+tab_name).length == 0){
        tab_name = "tab_info"; //fallback as the info tab
        link = $("#tab_info_link")
      }
    }
    $(".tab_link").removeClass('active');
    link.addClass('active');

    if(window.history.pushState) {
      var uri_parser = document.createElement("a");
      uri_parser.href = G_page_fullpermalink;
      window.history.pushState("","",uri_parser.pathname+"#"+tab_name.replace("tab_",""));
    }

    $("."+tab_name).show();
    if(tab_name == "tab_info"){
      initialize_map();
    }
    if(tab_name == "tab_wallet"){
      $('.wallet_container').masonry({
        itemSelector: '.wallet_doc',
        isAnimated: false,
        isFitWidth: true,
        columnWidth: 10
      });
    }
  });

  initialize_buddy();
  initialize_map();
  diveboard.plusone_go();
  //manage_responsiveness();
  //
  // Share button
  //
  share_initialize();

  //initialize following buttons
  initialize_follow_links();

  //review
  $(".leave_review").live('click', function(ev){
    load_review_form($(this).attr('data-db-shopvanity'), true);
  });

  //wallet
  init_wallet();
}

function show_gmaps_infowindow(marker){

  //console.log("showing infowindow for spot "+marker.spot_id);

  if (typeof infowindow != "undefined") {
    infowindow.close();
  }
  infowindow = new google.maps.InfoWindow({
            content: "<p>"+I18n.t(["js","user_home","Loading..."])+"</p><center><img src='/img/loading.gif'/></center>"
        });
  infowindow.open(map,marker);
  data ={
    'authenticity_token': auth_token,
    spot_id: marker.spot_id,
    owner_id: G_owner_api.id
  };
  $.ajax({
      url: '/api/user_dives_on_spot',
      dataType: 'json',
      data: data,
      type: "POST",
      success: function(data){
        content = data.spot.name+", "+data.spot.location_name+", "+data.spot.country_name+"<br/>";
        $.each(data.dives, function(idx, el){
          content += "<a href='"+el.permalink+"'  onclick='showDive("+el.id+"); return(false);' >"+el.date+", "+el.duration+I18n.t(["js","user_home","mins"])+", "+unit_distance(el.maxdepth, true)+"</a>"
          content += "<br/>";
        });
        infowindow.setContent(content);
      },
      error: function(data){

      }
    });


}



function initialize_map(){
  if (diveboard.postpone_me_load()) return;
  //
  // Map initialisation
  //
  try {
    // Origins, anchor positions and coordinates of the marker
    // increase in the X direction to the right and in
    // the Y direction down.
    G_marker_image = new google.maps.MarkerImage('/img/marker.png',
        // This marker is 20 pixels wide by 32 pixels tall.
        new google.maps.Size(19, 23),
        // The origin for this image is 0,0.
        new google.maps.Point(0,0),
        // The anchor for this image is the base of the flagpole at 0,23.
        new google.maps.Point(5, 28));
    G_marker_shadow = new google.maps.MarkerImage('/img/mark_shadow.png',
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
      var spot_id = G_user_spots_data[i].id;
      mark.spot_id = spot_id;
       google.maps.event.addListener(mark, 'click',
          function() {
            show_gmaps_infowindow(this);
          }
        );
      all_markers.push(mark);
    }

    for (i=0; i < G_user_extra_spots.length; i++)
    {
      var latLng = new google.maps.LatLng(G_user_extra_spots[i].lat, G_user_extra_spots[i].lng);
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
      //google.maps.event.addListener(mark, 'click',
      //    function() {
      //      show_gmaps_infowindow(this);
      //    }
      //  );
      all_markers.push(mark);
    }
    var isLarge=false;
    if($(window).width()>730){
      isLarge  = true;
    }
    var latlng;
    if (G_user_spots_data.length > 0)
      latlng = latlngbnds.getCenter();
    else
      latlng = new google.maps.LatLng(15, 0);
    var myOptions = {
      draggable: isLarge,
      scrollwheel: isLarge,
      zoom: 1,
      maxZoom: 13,
      center: latlng,
      streetViewControl: false,
      mapTypeId: google.maps.MapTypeId.TERRAIN
    };
    map = new google.maps.Map(document.getElementById("map_user"), myOptions);
    if (G_user_spots_data.length > 0)
    {
      map.fitBounds(latlngbnds);
      zoomChangeBoundsListener = google.maps.event.addListener(map,'bounds_changed',function (event) {
          google.maps.event.removeListener(zoomChangeBoundsListener);
          if (map.getZoom()>4) map.setZoom(4);
        });
    }

    //Setting up the clusterer
    G_markerCluster = new MarkerClusterer(map, []);
    G_markerCluster.setGridSize(45);
    G_markerCluster.setMaxZoom(11);
    G_markerCluster.addMarkers(all_markers);
  } catch(e){}

}


var G_edit_values = null;
function switch_to_edit_mode()
{
  G_edit_mode = true;
  $(".tab_link.active").click();//show edit form
  $(".not_editable_form").hide();
  $(".tab_link:not(.editable_tab)").hide();//we remove non editable tabs
  if (G_edit_values) {
    $.each(G_edit_values, function(index, element){
      if ('val' in element) {
        $(element.elt).val(element.val);
        $(element.elt).attr('checked', element.checked);
      } else if ('html' in element){
        $(element.elt).html(element.html);
      }
    });
  } else {
    G_edit_values = [];
    $(".editable_input").each(function(index, element){
      if ($.inArray(element.tagName, ['INPUT', 'TEXTAREA', 'SELECT'])>=0)
        G_edit_values.push({elt: element, val: $(element).val(), checked: $(element).attr('checked')});
      else
        G_edit_values.push({elt: element, html: $(element).html()});
    });
  }
  if(G_private_user.about != null && G_private_user.about != "") {
    $("#userhome_edit_aboutme").html(G_private_user.about)
  }else{
    $("#userhome_edit_aboutme").html("");
  }
  if(G_private_user.total_ext_dives != null)
    $("#userhome_edit_total_ext_dives").val(G_private_user.total_ext_dives);
  else
    $("#userhome_edit_total_ext_dives").val(0);

  //diveboard.mask_file(false, {'z-index': 8000});
  //$("#userhome_edit_aboutme").val($("#userhome_value_aboutme").text());
  //$(".editable").hide();
  $(".editable_form").show();
  init_qualifications();
  init_user_edit();
  init_avatar_edit();
  init_dive_pagination();
  $("#userhome_edit_total_ext_dives_edit").val(G_private_user.total_ext_dives);
  //diveboard.mask_file(false, {'z-index': 8000});
  window.onbeforeunload = confirmExit;
  function confirmExit()
  {
    return I18n.t(["js","user_home","You have attempted to leave this page.  If you have made any changes to the fields without clicking the Save button, your changes will be lost.  Are you sure you want to exit this page?"]);
  }
}

G_init_qualifications = false;
function init_qualifications(){
  if(G_init_qualifications)
    return;
  G_init_qualifications = true;
  $(function() {
    $( "#sortable1, #sortable2" ).sortable({
      connectWith: ".connectedSortable"
    }).disableSelection();
  });
  $("#add_qualification").click(add_qualification);

  $("#qualif_date_picker").datepicker({
      dateFormat: 'yy-mm-dd',
      changeMonth: true,
      changeYear: true,
      yearRange: '-100:+1',
      onSelect: function(dateText, inst) {
          $("#qualif_date_picker").removeClass("wizard_input_error");
        },
      onClose: function(dateText, inst) {
        if (!dateText.match(/[0-9]{4}-[0-9]{2}-[0-9]{2}/) && dateText.length > 10){
          $("#qualif_date_picker").val("");
          }
        }
      });
  $.datepicker.setDefaults($.datepicker.regional[$("html").attr("lang") || 'en']);


  if (G_private_user.qualifications){
    //we have some qualifications in base
    if (G_private_user.qualifications.featured != null ){
      for(var i=0; i< G_private_user.qualifications.featured.length; i++) add_qualif(1, G_private_user.qualifications.featured[i]);
    }
    if (G_private_user.qualifications.other != null ){
      for(var i=0; i< G_private_user.qualifications.other.length; i++) add_qualif(2, G_private_user.qualifications.other[i]);
    }
  }
}

function add_qualif(listnum, qualif){
  var item = '<li class="settings_cert_box_line" data=\''+JSON.stringify(qualif)+'\'><div class="settings_cert_box_one">'+qualif.org+'</div> <div class="settings_cert_box_two">'+qualif.title+'</div><div class="settings_cert_box_three">'+qualif.date+'</div><div class="settings_cert_box_four"><a href="#" onclick="delete_qualif(this);return false;">x</a></div></li>';
  if (listnum==1) $("#sortable1").append(item);
  if (listnum==2) $("#sortable2").append(item);
}
function add_qualification(ev){
  ev.preventDefault();
  var qualif = {};
  var error = false;
  $("#qualif_orga").removeClass("wizard_input_error");
  $("#qualif_title").removeClass("wizard_input_error");
  $("#qualif_date_picker").removeClass("wizard_input_error");


  if (!isDate($("#qualif_date_picker").val())){ $("#qualif_date_picker").addClass("wizard_input_error"); error=true;}

  if ($("#qualif_orga").val() == "" || $("#qualif_orga").val() == I18n.t(["js","user_home","Organization"])) { $("#qualif_orga").addClass("wizard_input_error"); error=true;}
  if ($("#qualif_title").val().replace(/(^[\s]+|[\s]+$)/g, '') == I18n.t(["js","user_home","Enter Certification Title Here"]) || $("#qualif_title").val().replace(/(^[\s]+|[\s]+$)/g, '') == "") { $("#qualif_title").addClass("wizard_input_error"); error=true;}
  if ($("#qualif_date_picker").val().replace(/(^[\s]+|[\s]+$)/g, '') == null || $("#qualif_date_picker").val().replace(/(^[\s]+|[\s]+$)/g, '') == "") { $("#qualif_date_picker").addClass("wizard_input_error"); error=true;}

  if(!error){
    qualif.org = $("#qualif_orga").val().replace(/(^[\s]+|[\s]+$)/g, '');
    qualif.title = $("#qualif_title").val().replace(/(^[\s]+|[\s]+$)/g, '');
    qualif.date = $("#qualif_date_picker").val().replace(/(^[\s]+|[\s]+$)/g, '');

    $("#qualif_orga").val(I18n.t(["js","user_home","Organization"]));
    $("#qualif_title").val("");
    $("#qualif_date_picker").val("2011-01-01");

    $("#qualif_orga").removeClass("wizard_input_error");
    $("#qualif_title").removeClass("wizard_input_error");
    $("#qualif_date_picker").removeClass("wizard_input_error");

    add_qualif(2, qualif);
    }
}

function delete_qualif(item){
//  ev.preventDefault();
  $(item).parent().parent().remove();
}

G_user_edit_init=false;
function init_user_edit(){
  if(G_user_edit_init)
    return;
  G_user_edit_init = true;
  $("#nickname").keyup(check_nickname);
  $.ui.autocomplete.prototype._renderItem = function (ul, item) {
    item.label = item.label.replace(new RegExp("(?![^&;]+;)(?!<[^<>]*)(" + $.ui.autocomplete.escapeRegex(this.term) + ")(?![^<>]*>)(?![^&;]+;)", "gi"), "<strong>$1</strong>");
    return $("<li></li>")
    .data("item.autocomplete", item)
    .append("<a>" + item.label + "</a>")
    .appendTo(ul);
  };



  //this is initialisation....
  var country = G_private_user.location || "blank";
  //alert(country);
  $($("#country").prev()).attr("src","/img/flags/"+country.toLowerCase()+".gif");
  $("#country").attr("shortname", country.toLowerCase());
  if (country.toLowerCase() != "blank") {
    $("#country").val(country_name_from_code(country));
    country_ok = true;
    $("#country").css("border", "")
  }else{
    country_ok = false;
  }


  $("#tagid").keyup(check_tagid);
  tagid_ok =true;



    //// City / Country


    var addresspickerMap = $( "#settings_address" ).addresspicker({
      draggableMarker: false,
      mapOptions: {
        zoom: (G_private_user.lat==undefined || G_private_user.lng==undefined)?0:(G_private_user.city==undefined?3:6)
      },
      elements: {
        map:      "#settings_address_map",
        lat:      "#settings_address_lat",
        lng:      "#settings_address_lng",
        locality: "#settings_address",
        country:  "#country"
      }
    });

  $( "#settings_address" ).on( "keypress", function( event, ui ) {
    //console.log(event.charCode);
    if (event.charCode > 13) {
      //console.log("change");
      $("#address_ok").hide();
      $("#address_nok").show();
      $("#country").val("");
      $("#country").attr("shortname","blank");
      $($("#country").prev()).attr("src","/img/flags/blank.gif");
      country_ok = false;
    }else{
      event.preventDefault();
      event.stopPropagation();
    }
  });

  $( "#settings_address" ).on( "autocompleteselect", function( event, ui ) {
    //console.log("selected");
    $("#address_ok").show();
    $("#address_nok").hide();
    var code = $("#country").attr("shortname");
    var country_name = country_name_from_code(code);
    if (code != "" && country_name != "")
    {
      $($("#country").prev()).attr("src","/img/flags/"+code.toLowerCase()+".gif");
      $("#country").html(country_name);
      $("#country").css("border", "")
      country_ok = true;
    }else{
      country_ok = false;
      $($("#country").prev()).attr("src","/img/flags/blank.gif");
      $("#country").html("");
    }
  });


}

var tagid_xhr;
function check_tagid(){
  //grabs status of a tag
  if($("#tagid").val().match(/^\ *$/)){
    if(tagid_xhr) tagid_xhr.abort();
    $("#tagid_search").hide();
    $("#tagid_ok").hide();
    $("#tagid_nok").hide();
    tagid_ok = true;
    return
  }
  if(tagid_xhr) tagid_xhr.abort();


    $("#tagid_search").show();
    $("#tagid_ok").hide();
    $("#tagid_nok").hide();

  tagid_xhr = $.ajax({
    url:"/api/check_tagid",
    data:({
        shaken_id: $("#tagid").val(),
        'authenticity_token': auth_token
      }),
    type:"POST",
    dataType:"json",
    error: function(data) {
      if (data.statusText == 'abort') return;
      diveboard.alert(I18n.t(["js","user_home","A technical error occured while checking the validity of the email. Please try again."]));
    },
    success:function(data){
      if (data.success) {
        if (data.status == "available"){
          $("#tagid_search").hide();
          $("#tagid_ok").show();
          $("#tagid_nok").hide();
          tagid_ok =true;
        }else if (data.status == "assigned" && data.user_id == G_user_api.shaken_id){
          $("#tagid_search").hide();
          $("#tagid_ok").show();
          $("#tagid_nok").hide();
          tagid_ok =true;
        }else if (data.status == "assigned" && data.user_id != G_user_api.shaken_id){
          $("#tagid_search").hide();
          $("#tagid_ok").hide();
          $("#tagid_nok").show();
          tagid_ok = false;
          diveboard.notify(I18n.t(["js","user_home","Wrong tag id"]), I18n.t(["js","user_home","This is already affected to another user"]));
        }else{
          $("#tagid_search").hide();
          $("#tagid_ok").hide();
          $("#tagid_nok").show();
          tagid_ok = false;
        }
      } else {
        diveboard.alert(I18n.t(["js","user_home","A technical error occured while checking the validity of the email. Please try again."]));
      }

    }
  });


}

function check_nickname(){
  if ($("#nickname").val().replace(/(^[\s]+|[\s]+$)/g, '') != ""){
    $("#nickname_ok").show();
    $("#nickname_nok").hide();
    nickname_ok = true;
  }else{
    $("#nickname_ok").hide();
    $("#nickname_nok").show();
    nickname_ok = false;
  }

}
var G_avatar_edit_init = false;
function init_avatar_edit(){
  if (G_avatar_edit_init)
    return;
  G_avatar_edit_init = true;
  G_default_picture_url = G_private_user.picture_large;
  G_user_facebook_picture = "http://graph.facebook.com/v2.0/"+G_private_user.fb_id+"/picture?type=large";
  setup_avatar_upload();
  $("#image_cancel").click(reset_image);
  $("#image_ok_avatar").click(validate_image);
  $("#use_facebook").click(use_facebook_image);

}

function reset_image(ev){
  if (ev)
    ev.preventDefault();
  try {
    //Resetting the display of the upload
    $(".qq-upload-success").html('');
  } catch(e){}  $("#preview").attr("src",default_picture_url);
  $("#imageuploader").show();
  $("#picture_table").hide();
  $('#preview').css({
    width: 100 + 'px',
    height: 100 + 'px',
    marginLeft: '-' + 0 + 'px',
    marginTop: '-' + 0 + 'px'
  });
  selected_pic = default_selected_pic;

}

function validate_image(ev){
  if (ev)
    ev.preventDefault();
  $("#imageuploader").show();
  $("#picture_table").hide();
}

function use_facebook_image(ev){
  ev.preventDefault();
  try {
    //Resetting the display of the upload
    $(".qq-upload-success").html('');
  } catch(e){}
  $("#preview").attr("src",fb_image);
  $("#imageuploader").show();
  $("#picture_table").hide();
  $('#preview').attr({height: null, width: null})
  $('#preview').css({
    width: 100 + 'px',
    height: '',
    marginLeft: '-' + 0 + 'px',
    marginTop: '-' + 0 + 'px'
  });
  selected_pic = 0;
}



function showPreview(coords)
{
  var rx = 100 / coords.w;
  var ry = 100 / coords.h;

  crop_coords_w = coords.w;
  crop_coords_h = coords.h;
  crop_coords_x = coords.x;
  crop_coords_y = coords.y;
  crop_width = Math.round(rx * $("#pictureimg").width());
  crop_height = Math.round(ry * $("#pictureimg").height());
  crop_mleft = Math.round(rx * coords.x);
  crop_mright = Math.round(ry * coords.y);

  $('#preview').css({
    width: crop_width + 'px',
    height: crop_height + 'px',
    marginLeft: '-' + crop_mleft + 'px',
    marginTop: '-' + crop_mright + 'px'
  });
};



function submitPict(){
  //alert("Submitting Picture");
  $("#upload_image").submit();

}


function setup_avatar_upload(){
  var uploader = new qq.FileUploader({
      // pass the dom node (ex. $(selector)[0] for jQuery users)
      element: $("#settings_upload_btn")[0],
      // path to server-side upload script
      action: '/settings/uploadpict',
    // additional data to send, name-value pairs
    params: {
      user_id: G_private_user.id,
    'authenticity_token': auth_token
    },
    // validation
    // ex. ['jpg', 'jpeg', 'png', 'gif'] or []
    allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'gif', 'bmp'],
    // each file size limit in bytes
    // this option isn't supported in all browsers
    sizeLimit: 20971520, // max size
    //minSizeLimit: 0, // min size

    // set to true to output server response to console
    debug: false,

    // events
    // you can return false to abort submit
    onSubmit: function(id, fileName){
      //clean-up the mess....
      $(".qq-upload-list").empty();
    },
    onProgress: function(id, fileName, loaded, total){},
    onComplete: function(id, fileName, responseJSON){
      if (responseJSON["success"] == "false" || responseJSON["success"] == undefined) {
        $(".qq-upload-failed-text").show();
      }else{
        //do the dance
        upload_avatar_done(responseJSON["filename"]);
        $(".qq-upload-list").empty();
      }



    },
    onCancel: function(id, fileName){},

    messages: {
        // error messages, see qq.FileUploaderBasic for content
      typeError: I18n.t(["js","user_home","{file} has invalid extension. Only {extensions} are allowed."]),
                sizeError: I18n.t(["js","user_home","{file} is too large, maximum file size is {sizeLimit}."]),
                minSizeError: I18n.t(["js","user_home","{file} is too small, minimum file size is {minSizeLimit}."]),
                emptyError: I18n.t(["js","user_home","{file} is empty, please select files again without it."]),
                onLeave: I18n.t(["js","user_home","The files are being uploaded, if you leave now the upload will be cancelled."])
    },
    showMessage: function(message){ alert(message); }
  });

}


function upload_avatar_done(filename) { //Function will be called when iframe is loaded
  $("#upload_progress").hide();
  if(filename == "" || filename == null){
    //uplod actually failed
    $(".qq-upload-file").hide();
    $(".qq-upload-size").hide();
    $(".qq-upload-failed-text").show();
    return;
  }
  crop_pictname = filename;
  // WARNING => DO NOOOOOT CHANGE THE ORDER OF THE LOADING , it will fail....
  var im =$('<img id="pictureimg" />');
  im.bind("load",function(){
    //alert("picture has been loaded fully");
    //strip the pict so it shows up
    //if ( $("#picturepreview").find("img")[0].width > 450)  $($("#picturepreview").find("img")[0]).width(450)
    $("#imageuploader").hide();
    $("#picture_table").show();

    $("#pictureimg").Jcrop({
        onChange: showPreview,
        onSelect: showPreview,
        boxWidth: 400,
        setSelect:   [ 0, 0, 100, 100 ],
        aspectRatio: 1
      });
    selected_pic = 1;
  });
  $("#picturepreview").empty();
  $("#picturepreview").append(im);
  im.attr("src", "/tmp_upload/"+crop_pictname);
  $("#preview").attr("src", "/tmp_upload/"+crop_pictname);
}

function get_qualif_list(){
  var qualif_list = {};
  if($("#sortable1 li").length >0){
    qualif_list.featured=[];
    for (var i=0 ; i< $("#sortable1 li").length; i++)   qualif_list.featured[i]=JSON.parse($($("#sortable1 li")[i]).attr("data"));
  }
  if($("#sortable2 li").length >0){
    qualif_list.other=[];
    for (var i=0 ; i< $("#sortable2 li").length; i++)   qualif_list.other[i]=JSON.parse($($("#sortable2 li")[i]).attr("data"));
  }


  return qualif_list;
}


function save_edit_mode()
{
    window.onbeforeunload = null;
    diveboard.mask_file(true, {'z-index': 9900});
    var fav_dives = {};

    $(".fav_dives_chk").each(function(index){
      var dive_id = this.name.replace(/.*_/, "");
      fav_dives[dive_id] = this.checked;
    });
    var data = {
      'owner_id': G_owner_api.id,
      'about': $("#userhome_edit_aboutme").val(),
      'fav_dives': JSON.stringify(fav_dives),
      'total_ext_dives': $('#userhome_edit_total_ext_dives_edit').val(),
      'authenticity_token': auth_token,
      'nickname': $("#nickname").val(),
      'location': $("#country").attr("shortname"),
      'city': $("#settings_address").val(),
      'lat': $("#settings_address_lat").val(),
      'lng': $("#settings_address_lng").val(),
      'qualifications': JSON.stringify(get_qualif_list())
    }
    if (tagid_ok){
      data.tagid = $("#tagid").val();
    }
    if(typeof(selected_pic) != "undefined"){
      if(selected_pic == 0){
        data = $.extend(data, {'selected_pic': selected_pic});
      }else if (selected_pic == 1){
        data = $.extend(data, {
          'selected_pic': selected_pic,
          'crop_width': crop_width,
          'crop_height': crop_height,
          'crop_mleft': crop_mleft,
          'crop_mright': crop_mright,
          'crop_pictname': crop_pictname,
          'crop_coords_w': crop_coords_w,
          'crop_coords_h': crop_coords_h,
          'crop_coords_x': crop_coords_x,
          'crop_coords_y': crop_coords_y
        });
      }
    }
    $.ajax({
      url: '/api/update_logbook',
      dataType: 'json',
      data: data,
      type: "POST",
      success: function(data){
        if (data["success"] == 'false')
          this.error();
        else{
          if(data["errors"].length == 0){
            window.location.reload(true);
          }else{
            diveboard.unmask_file();
            var errors = "";
            $.each(data["errors"], function(idx, value){errors+=("<br/>"+value);})
            diveboard.notify(I18n.t(["js","user_home","Error saving your data"]), I18n.t(["js","user_home","Some data could not be saved:"])+" "+errors, function(){
              window.location.reload(true);
            });
          }
        }
      },
      error: function(data){
        alert(I18n.t(["js","user_home","Due to some technical error, your data has not been saved. You may want to try again after reloading the page."]));
        $('#file_mask').css('z-index', 9000)
      }
    });
}

function cancel_edit_mode()
{
  window.onbeforeunload = null;
  diveboard.unmask_file();
  $(".editable_form").hide();
  $(".not_editable_form").show();

  $(".editable").show();
  $(".tab_link:not(.editable_tab)").show();
  G_edit_mode = false;
  $(".tab_link.active").click();//we load the tab's non-edit version
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
        $('#diveboard_share_menu').css({
          left: $('#share_this_link').offset().left+$('#share_this_link').width()-$('#diveboard_share_menu').width(),
          top: $('#share_this_link').offset().top+$('#share_this_link').height(),
        });
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
var G_paginate_init=false;
function init_dive_pagination(){
  if(G_paginate_init)
    return;

  G_paginate_init = true;

    $("#userhome_edit_favorite_dives").pajinate({
          items_per_page : 10,
          num_page_links_to_display : 3,
          nav_label_first : '<<',
          nav_label_last : '>>',
          nav_label_prev : '<',
          nav_label_next : '>'
        });
  udpate_fave_dive_count();
  $("#userhome_edit_favorite_dives input").click(udpate_fave_dive_count);
  $("#userhome_edit_favorite_dives .page_data a").click(function(e){
    e.preventDefault();
    $.each($("#userhome_edit_favorite_dives input:checked"), function(idx, e){
      $(e).attr('checked', false);
    });
    udpate_fave_dive_count();
  })
}
function udpate_fave_dive_count(){
  $("#userhome_edit_favorite_dives .page_data span").html($("#userhome_edit_favorite_dives input:checked").length);
}


//////////////////////////////////////////////
//
//    BUDDIES
//
//////////////////////////////////////////////

function initialize_buddy(){
  $('.destitute_buddy').live('click', remove_my_buddy);
  $('.buddy_invite_submit').live('click', invite_external_buddy);
  $('.massbuddy_invite_submit').live('click', invite_external_buddies);
  $('.buddy_invite_fb').live('click', invite_facebook_buddy);
  $('.invite_fb_dialog').live('click', invite_facebook_friends);
  $('.buddy_invite_ask_email').live('click', invite_unknown_buddy);
  $('.ask_email_invite_cancel').live('click', function(){ $('#dialog-ask-email-invite').dialog('close')});
  $('.ask_email_invite_send').live('click', invite_unknown_buddy_send);
}

function remove_my_buddy(ev){
  if (ev) ev.preventDefault();

  diveboard.mask_file(true);

  var elt = $(this);
  var type = $(elt).attr('data-type');
  var id = $(elt).attr('data-id');

  var data_to_send = {id: G_private_user.id};

  data_to_send.buddies = [];
  for (var i in G_private_user.db_buddy_ids) {
    var lid = G_private_user.db_buddy_ids[i];
    if (lid != id || type != 'user')
      data_to_send.buddies.push({db_id: lid});
  }

  for (var i in G_private_user.ext_buddy_ids) {
    var lid = G_private_user.ext_buddy_ids[i];
    if (lid != id || type != 'external')
      data_to_send.buddies.push({id: lid});
  }

  $.ajax({
    url: '/api/V2/user',
    dataType: 'json',
    data: {
      arg: JSON.stringify(data_to_send),
      flavour: 'private',
      'authenticity_token': auth_token
    },
    type: "POST",
    success: function(data){
      if (data.success && (data.error == null||data.error.length==0)){
        G_private_user = data.result;
        elt.closest('.buddy_item').detach();
        diveboard.unmask_file();
      } else if (data.success) {
        diveboard.alert(I18n.t(["js","user_home","The data could not be completely updated"]), data, function(){
          window.location.replace(G_private_user.permalink);
        });

      } else {
        //detail the alert
        diveboard.alert(I18n.t(["js","user_home","A technical error occured."]), data, function(){
          diveboard.unmask_file();
        });
      }
    },
    error: function(data) {
      diveboard.alert(I18n.t(["js","user_home","A technical error occured while saving the dive. Please make sure your internet connection is up and try again."]), null, function() {
        diveboard.unmask_file();
      });
    }
  });
}

function invite_unknown_buddy(ev){
  var elt = $(this);
  var id = elt.attr('data-external-id');
  $("#dialog-ask-email-invite .buddy_name").text(elt.attr('data-external-nickname'));
  $("#dialog-ask-email-invite .buddy_id").val(id);
  $("#dialog-ask-email-invite .buddy_id").data('invite_button', elt);
  $("#dialog-ask-email-invite .buddy_email").val('');
  $("#dialog-ask-email-invite").dialog({
    resizable: false,
    modal: true,
    width: '600px',
    zIndex: 99999
  });
}

function invite_unknown_buddy_send(){
  diveboard.mask_file(true);
  $("#dialog-ask-email-invite").dialog('close');
  var id = $("#dialog-ask-email-invite .buddy_id").val();
  var email = $("#dialog-ask-email-invite .buddy_email").val()
  var invite_button = $("#dialog-ask-email-invite .buddy_id").data('invite_button');
  api_invite_call(invite_button, id, email);
};

function invite_external_buddy(ev){
  if (ev) ev.preventDefault();

  diveboard.mask_file(true);

  var elt = $(this);
  var id = $(elt).attr('data-external-id');

  api_invite_call(elt, id, null);
}

function api_invite_call(invite_button, id, email){
  var data_to_send = {
    'authenticity_token': auth_token,
    external_user_id: id
  };

  if (email){
    data_to_send.email = email;
  }
  $.ajax({
    url: '/api/invite_buddy',
    dataType: 'json',
    data: data_to_send,
    type: "POST",
    success: function(data){
      if (data.success && (data.error == null||data.error.length==0)){
        diveboard.notify(I18n.t(["js","user_home","Invitation"]), I18n.t(["js","user_home","An invitation mail has been sent. We hope to hear of your friend soon!"]), function(){
          var now = new Date();
          invite_button.closest('.buddy_item').find('.invitation_date').text(""+now.getFullYear()+"-"+(1+now.getMonth())+'-'+now.getDate());
          invite_button.detach();
          diveboard.unmask_file();
        });
      } else if (data.success) {
        diveboard.alert(I18n.t(["js","user_home","Some technical mischief happened: the mail has NOT been sent."]), data, function(){
          diveboard.unmask_file();
        });

      } else {
        //detail the alert
        diveboard.alert(I18n.t(["js","user_home","A technical error occured."]), data, function(){
          diveboard.unmask_file();
        });
      }
    },
    error: function(data) {
      diveboard.alert(I18n.t(["js","user_home","A technical error occured while saving the dive. Please make sure your internet connection is up and try again."]), null, function() {
        diveboard.unmask_file();
      });
    }
  });
}

function invite_external_buddies(){
  //diveboard.mask_file();
  data_to_send = {
    'authenticity_token': auth_token
  };
  data_to_send.bulk_email = $('.invite_email_list').val();

  $.ajax({
    url: '/api/invite_buddy',
    dataType: 'json',
    data: data_to_send,
    type: "POST",
    success: function(data){
      if (data.success && (data.error == null||data.error.length==0)){
        diveboard.notify(I18n.t(["js","user_home","Invitation"]), I18n.t(["js","user_home","Your %{count} invitations have been sent by mail. We hope to hear of your friends soon !"], {count: data.result.sent}), function(){
          window.location.replace(G_private_user.permalink);
        });
      } else if (data.success) {
        diveboard.alert(I18n.t(["js","user_home","Some technical mischief happened: the mail has NOT been sent."]), data, function(){
          diveboard.unmask_file();
        });

      } else {
        //detail the alert
        diveboard.alert(I18n.t(["js","user_home","A technical error occured."]), data, function(){
          diveboard.unmask_file();
        });
      }
    },
    error: function(data) {
      diveboard.alert(I18n.t(["js","user_home","A technical error occured while saving the dive. Please make sure your internet connection is up and try again."]), null, function() {
        diveboard.unmask_file();
      });
    }
  });
}


function invite_facebook_buddy(){
  var elt = $(this);
  var fb_id = elt.attr('data-external-fbid');
  FB.ui({
    method: 'send',
    to: fb_id,
    name: 'Diveboard: your online scuba logbook',
    link: 'http://www.diveboard.com'
  },
  function(response){
    if (response.success) {
      var now = new Date();
      elt.closest('.buddy_item').find('.invitation_date').text(""+now.getFullYear()+"-"+(1+now.getMonth())+'-'+now.getDate());
      $.ajax({
        url: '/api/invite_buddy',
        dataType: 'json',
        data: {external_user_id: elt.attr('data-external-id')},
        type: "POST"
      });
      elt.detach();
    }
  });
}


function invite_facebook_friends(ev){
  FB.ui({method: 'apprequests',
    title: I18n.t(["js","user_home","Invite your friends to Diveboard"]),
    message: I18n.t(["js","user_home","Diveboard is an online scuba logbook, and THE place where to find your next place to dive"])
  }, function(response){
    if (!response || response.error_code) return;

    diveboard.mask_file(true);

    var data_to_send = {id: G_private_user.id};
    data_to_send.buddies = [];
    //Current list of buddies
    for (var i in G_private_user.db_buddy_ids) {
      var lid = G_private_user.db_buddy_ids[i];
      data_to_send.buddies.push({db_id: lid});
    }

    for (var i in G_private_user.ext_buddy_ids) {
      var lid = G_private_user.ext_buddy_ids[i];
      data_to_send.buddies.push({id: lid});
    }

    //Adding new fb buddies
    for (var i in response.to) {
      data_to_send.buddies.push({fb_id: response.to[i], invited: true});
    }

    $.ajax({
      url: '/api/V2/user',
      dataType: 'json',
      data: {
        arg: JSON.stringify(data_to_send),
        flavour: 'private',
        'authenticity_token': auth_token
      },
      type: "POST",
      success: function(data){
        if (data.success && (data.error == null||data.error.length==0)){
          G_private_user = data.result;


          window.location.replace(G_private_user.permalink);


        } else if (data.success) {
          diveboard.alert(I18n.t(["js","user_home","The data could not be completely updated"]), data, function(){
            window.location.replace(G_private_user.permalink);
          });

        } else {
          //detail the alert
          diveboard.alert(I18n.t(["js","user_home","A technical error occured."]), data, function(){
            diveboard.unmask_file();
          });
        }
      },
      error: function(data) {
        diveboard.alert(I18n.t(["js","user_home","A technical error occured while saving the dive. Please make sure your internet connection is up and try again."]), null, function() {
          diveboard.unmask_file();
        });
      }
    });



  });
}



//Wallet

function init_wallet(){
  diveboard.setup_crop_upload({
    selector: '.wallet_uploader',
    user_id: G_user_api.id,
    crop:true,
    box_width: 300,
    aspect_ratio: null,
    preview: null,
    allow_images: true,
    allow_videos: false,
    allow_docs: true,
    cancel: function(){},
    confirm: function(api){ //called with api==null if not cropable
      api.reset();
      var crop = api.tellSelect();
      diveboard.mask_file(true);
      $.ajax({
        url: '/api/picture/upload',
        data: {
          user_id: G_user_api.id,
          from_tmp_file: api.getPictname(),
          crop_x0: crop && crop.x,
          crop_y0: crop && crop.y,
          crop_width: crop && crop.w,
          crop_height: crop && crop.h,
          album: 'wallet',
          flavour: 'private',
          'authenticity_token': auth_token
        },
        dataType: "json",
        success: function(data){
          if (data.success) {
            var line = $("<div class='wallet_doc'><div class='wallet_img'><a href='#' target='_blank' class='download_link'><img src=''/></a></div><div class='notes'></div></div>");
            line.attr('data-doc_id', data.result.id);
            line.attr('data-download_url', data.result.original_document_download_url);
            line.find('img').attr('src',data.result.small);
            line.find('a').attr('href',data.result.original_document_url);
            $('.wallet_container').append(line);
            $('.wallet_container').masonry('appended', line);
            line.imagesLoaded(function(){
              $('.wallet_container').masonry('reload');
            });
          } else {
            diveboard.alert(I18n.t(["js","user_home","A technical error occured while cropping the picture"]), data);
          }
          diveboard.unmask_file();
        },
        error: function(data){
          diveboard.alert(I18n.t(["js","user_home","A technical error occured while cropping the picture"]), data);
          diveboard.unmask_file();
        }
      });
    }
  });

  container = $('.wallet_container');
  container.imagesLoaded(function(){
    container.masonry({
      itemSelector: '.wallet_doc',
      isAnimated: false,
      isFitWidth: true,
      columnWidth: 10
    });
  });

  $('.wallet_doc').live('mouseenter', function(ev){
    ev.preventDefault();
    var doc=$(this);
    var container = doc.closest('.wallet_container');
    var menu = container.find('.wallet_doc_menu');
    menu.appendTo(doc);
    menu.css({ left: 0, top: 0 });
    menu.show();
    doc.one('mouseleave', function(){menu.hide();});
    $('body').one('click', function(){menu.hide();});
  });

  $('.wallet_doc_menu .download').live('click', function(ev){
    ev.preventDefault();
    var arrow=$(this);
    var doc = arrow.closest('.wallet_doc');
    var menu = doc.find('.wallet_doc_menu');
    menu.hide();
    var download_url = doc.attr('data-download_url');
    if (download_url)
      window.location = download_url;
    else
      window.location = doc.find('.download_link').attr('href');
  });

  $('.wallet_doc_menu .delete').live('click', function(ev){
    ev.preventDefault();
    var arrow=$(this);
    var doc = arrow.closest('.wallet_doc');
    var id = doc.attr('data-doc_id');
    var container = arrow.closest('.wallet_container');
    var menu = doc.find('.wallet_doc_menu');
    var actions = {};
    menu.hide();
    container.append(menu);
    actions[I18n.t(["js","user_home","Yes"])] = function(){
        diveboard.mask_file(true);
        $.ajax({
          url: '/api/V2/picture/'+id,
          dataType: 'json',
          data: {
            'authenticity_token': auth_token
            },
          type: "DELETE",
          success: function(data){
            if (data["success"] == 'false')
              this.error();
            else {
              doc.detach();
              $('.wallet_container').masonry('reload');
            }
            diveboard.unmask_file();
          },
          error: function(data){
            alert(I18n.t(["js","user_home","Due to some technical error, the document has not been deleted. You may want to try again after reloading the page."]));
            diveboard.unmask_file();
          }
        });
      };
    actions[I18n.t(["js","user_home","No"])] = function(){};
    diveboard.propose(I18n.t(["js","user_home","Delete document"]), I18n.t(["js","user_home","This will definitely delete the document from Diveboard. Are you sure?"]), actions)
  });
}

