function logbook_shop_home_initialize() {

 G_saved_form = $("#formedit_shop").html();

 $(".tab_link").live('click', function(e) {
    if (e) e.preventDefault();
    var link = $(this);
    var tab_name = link.attr('id').replace(/_link$/,'');
    $(".tab_link").removeClass('active');
    link.addClass('active');
    $(".tab_panel").hide();
    $("."+tab_name).show();
    initialize_shop_location_map();
    initialize_map_editor();
    initialize_editors();
  });

  $(".shop_see_reviews").live('click', function(e) {
    if (e && $("#tab_reviews_link").is(':visible')){
      $("#tab_reviews_link").click();
      e.preventDefault();
    }
  });

  $("#sidebar .shop_see_profile").live('click', function(e){
    if (e && $("#tab_reviews_link").is(':visible')){
      if ($("#tab_info_link").is(':visible'))
        $("#tab_info_link").click();
      else if ($("#tab_location_link").is(':visible'))
        $("#tab_location_link").click();
      else
        $("#tab_reviews_link").click();
      e.preventDefault();
    }
  });

  $(".leave_review_shop").live('click',function(e){
    if (e) e.preventDefault();
    open_new_review_form();
  });

  $('.edit_link').live('click', function(e){
    if(e) e.preventDefault();

    window.onbeforeunload = confirmExit;
    function confirmExit()
    {
      return I18n.t(["js","shop_home","You have attempted to leave this page.  If you have made any changes to the fields without clicking the Save button, your changes will be lost.  Are you sure you want to exit this page?"]);
    }

    intialize_autocomplete();
    setup_file_upload();
    //TODO!!!! diveboard.setup_crop_upload('#logo_upload_ctl');
    reset_image();
    $(".editable").hide();
    $("#formedit_shop").show();
    $(".tab_link").hide();
//    $(".editable_form").show();
    $(".editable_controls").show();
    $(".editable_tab").show();
    $(".tab_link:visible").first().click();
    initialize_editors();
    if ($("#shopedit_gmap").is(':visible')) {
      var lat = diveboard.isNumeric( $("#shopedit_lat").val() )? $("#shopedit_lat").val() : 0;
      var lng = diveboard.isNumeric( $("#shopedit_lng").val() )? $("#shopedit_lng").val() : 0;
      gmaps_initialize("shopedit_gmap", true, lat, $("#shopedit_lng").val() || 0, 11);
    }
  });

  $(".shop_edit_cancel").live('click', function(e){
    if(e) e.preventDefault();

    window.onbeforeunload = null;


    $(".editable").show();
    $("#formedit_shop").hide();
    $(".tab_link").show();
    $(".tab_edit_only").hide();
 //  $(".editable_form").hide();
    $(".editable_controls").hide();
    $("#formedit_shop").html(G_saved_form);
    $(".tab_link:visible").first().click();
    initialize_shop_location_map(); //in case we're on the location tab and the map hadn't been init-zed before
    display_list_ad();
  });

  $(".shop_edit_save").live('click', function(e){
    if(e) e.preventDefault();
    shop_edit_save();
  });

  $(".fav_dives_chk").live('click', function(e){
    G_changed_dives = true;
  });

  $('.review_more').live('click', function(e){
    if(e) e.preventDefault();
    $(this).closest('.review_body').find('.review_abstract').hide();
    $(this).closest('.review_body').find('.review_detail').show();
  });

  $('.review_less').live('click', function(e){
    if(e) e.preventDefault();
    $(this).closest('.review_body').find('.review_abstract').show();
    $(this).closest('.review_body').find('.review_detail').hide();
  });


  $(".shop_edit_structure .list_option").live('click', function(e){
    if (e) e.preventDefault();
    $('.shop_edit_structure .list_option').removeClass('active');
    $(this).addClass('active');
  });

  try {
    share_initialize();
  } catch(e){
    if (console && console.log)
      console.log(e.message);
  }

  //Get to the right tab if requested
  try {
    var local_hash = self.document.location.hash.replace('#', '');
    if (local_hash)
      $("#tab_"+local_hash+"_link").click();
  } catch(e){
    if (console && console.log)
      console.log(e.message);
  }

  //initialize standard display
  initialize_form_review({
    on_success: function(data){
      if (data.success && (data.error == null||data.error.length==0)){
        window.location.replace(G_shop_api.permalink+"/review");
      } else if (data.success) {
        diveboard.alert(I18n.t(["js","shop_home","The data could not be completely updated"]), data, function(){
          window.location.replace(G_shop_api.permalink+"/review");
        });

      } else {
        //detail the alert
        diveboard.alert(I18n.t(["js","shop_home","A technical error occured."]), data, function(){
          diveboard.unmask_file();
        });
      }
    }
  });
  initialize_shop_claim();
  initialize_shop_location_map();
  initialize_map_editor();
  initialize_ad();
  initialize_review_reply();
}

function intialize_autocomplete()
{
  $(".autocomplete_country input").removeClass('ui-autocomplete-input');
  $(".autocomplete_country input").addClass('ui-autocomplete-input example');

  $(".autocomplete_country input").autocomplete({  source : countries,
    select: function(event, ui) {
      //get spot details and show them
      //selected is ui.item.id
      $(this).closest('.autocomplete_country').find('img').attr("src","/img/flags/"+ui.item.name.toLowerCase()+".gif");
      $(this).attr("shortname",ui.item.name.toLowerCase());
    },
    close: function(event, ui){
    //show_flag();
    },
    autoFill:true
  });
}

function share_initialize(){
  //Get the screen height and width
  var maskHeight = $(document).height();
  var maskWidth = $(window).width();
  var rendered = false;
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

    $('#diveboard_share_menu').fadeIn('fast', function(){
      if ( !rendered ){
        diveboard.plusone_go();
        rendered = true;
      }});
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


function initialize_shop_location_map()
{
  var lat = diveboard.isNumeric( G_shop_api['lat'] )? G_shop_api['lat'] : 0;
  var lng = diveboard.isNumeric( G_shop_api['lng'] )? G_shop_api['lng'] : 0;


  var zoom = 11;

  if (initialize_shop_location_map.initialized) return;
  if (!$("#map_location_holder").is(":visible")) return;
  initialize_shop_location_map.initialized = true;

  try {
    marker_shop_highlight = new google.maps.MarkerImage('/img/explore/marker_shop.png',
        new google.maps.Size(14, 14),
        new google.maps.Point(0,0),
        new google.maps.Point(7, 7));
    marker_shop_shadow = new google.maps.MarkerImage('/img/explore/marker_shop_shadow.png',
        new google.maps.Size(14, 15),
        new google.maps.Point(0,0),
        new google.maps.Point(7, 10));

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
    map = new google.maps.Map(document.getElementById("map_location_holder"),myOptions);
    var myLatLng = new google.maps.LatLng(lat,lng);
    marker = new google.maps.Marker({
      position: myLatLng,
      map: map,
      icon: marker_shop_highlight,
      shadow: marker_shop_shadow,
      draggable: false
    });
  } catch(e){}
}

function initialize_map_editor()
{
  if (!$("#shopedit_gmap").is(':visible'))
    return;

  var lat, lng, zoom, show_shop_pin;

  if (!diveboard.isNumeric($("#shopedit_lat").val()) || !diveboard.isNumeric($("#shopedit_lng").val()) ){
    lat = 0;
    lng = 0;
    zoom = 1;
    show_shop_pin = false;
  } else {
    lat = $("#shopedit_lat").val();
    lng = $("#shopedit_lng").val();
    zoom = 11;
    show_shop_pin = true;
  }

  try {
    var image = new google.maps.MarkerImage('/img/explore/marker_shop.png',
      new google.maps.Size(14, 14),
      new google.maps.Point(0,0),
      new google.maps.Point(7, 7)
    );
    var shadow = new google.maps.MarkerImage('/img/explore/marker_shop_shadow.png',
      new google.maps.Size(14, 15),
      new google.maps.Point(0,0),
      new google.maps.Point(7, 10));

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
    map = new google.maps.Map(document.getElementById("shopedit_gmap"),myOptions);
    var marker = new google.maps.Marker({
      position: latlng,
      map: map,
      icon: image,
      shadow: shadow,
      visible: show_shop_pin,
      draggable: true
    });

    google.maps.event.addListener(marker, 'dragend', function() {
      //infowindow.open(map,marker);
      map.setCenter(marker.position);
      var lat = marker.position.lat();
      var lng = marker.position.lng();
      $("#shopedit_lat").val(lat);
      $("#shopedit_lng").val(lng);
    });

    $("#shopedit_lat, #shopedit_lng").live('change', function(){
      var lat = parseFloat($("#shopedit_lat").val());
      var lng = parseFloat($("#shopedit_lng").val());
      if ( diveboard.isNumeric($("#shopedit_lat").val()) && diveboard.isNumeric($("#shopedit_lng").val()) ) {
        var latlng = new google.maps.LatLng(lat, lng);
        marker.setPosition(latlng);
        marker.setVisible(true);
        map.setCenter(marker.position);
        place_pin_button.hide();
      } else {
        marker.setVisible(false);
        place_pin_button.show();
      }
    });

    $("#shopedit_gmap_placepin").live('click', function(){
      var center = map.getCenter();
      marker.setPosition(center);
      $("#shopedit_lat").val(center.lat());
      $("#shopedit_lng").val(center.lng());
      marker.setVisible(true);
      place_pin_button.hide();
    });

    var place_pin_button = $("#shopedit_gmap_placepin").detach();
    place_pin_button.css('margin', '10px');
    map.controls[google.maps.ControlPosition.TOP_RIGHT].push(place_pin_button[0]);
    if (show_shop_pin) place_pin_button.hide();
    else place_pin_button.show();

  } catch(e){
    if (console && console.log)
      console.log(e.message)
  }
}





function open_new_review_form()
{
  reset_form_review();

  $("#dialog-enter-review").dialog({
      resizable: false,
      modal: true,
      width: '700px',
      zIndex: 99999,
      buttons: {}
  });
}

function initialize_editors()
{
  //modal text editor used throughout diveboard to edit texts stored in the wiki database
  elRTE.prototype.options.panels.diveboard_edit_panel1 = [
    'formatblock', 'removeformat'
  ];
  elRTE.prototype.options.panels.diveboard_edit_panel2 = [
    'bold', 'italic', 'underline', 'justifyleft', 'justifyright',
    'justifycenter', 'justifyfull',
     'insertorderedlist', 'insertunorderedlist',
    'link', 'image', 'flash'//, 'stopfloat'
  ];
  elRTE.prototype.options.toolbars.diveboardtoolbar = ['diveboard_edit_panel1', 'undoredo', 'alignment', 'diveboard_edit_panel2'];

  var opts = {
          cssClass : 'el-rte',
          lang     : I18n.locale,
          height   : 400,
          toolbar  : 'diveboardtoolbar',
          cssfiles : ['/mod/elrte/css/elrte-inner.css']
        }

  $('#shop_edit_about:visible, #shop_edit_nearby:visible').elrte(opts);
}

////////////////////////////////////////////////////
//
//  AVATAR UPLOAD & CROPPING FUNCTIONS
//
////////////////////////////////////////////////////


function setup_file_upload(){
  var uploader = new qq.FileUploader({
      // pass the dom node (ex. $(selector)[0] for jQuery users)
      element: $("#settings_upload_btn")[0],
      // path to server-side upload script
      action: '/settings/uploadpict',
    // additional data to send, name-value pairs
    params: {
      user_id: G_user_proxy_id,
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
      uploadDone(responseJSON["filename"]);
      }



    },
    onCancel: function(id, fileName){},

    messages: {
        // error messages, see qq.FileUploaderBasic for content
      typeError: I18n.t(["js","shop_home","{file} has invalid extension. Only {extensions} are allowed."]),
                sizeError: I18n.t(["js","shop_home","{file} is too large, maximum file size is {sizeLimit}."]),
                minSizeError: I18n.t(["js","shop_home","{file} is too small, minimum file size is {minSizeLimit}."]),
                emptyError: I18n.t(["js","shop_home","{file} is empty, please select files again without it."]),
                onLeave: I18n.t(["js","shop_home","The files are being uploaded, if you leave now the upload will be cancelled."])
    },
    showMessage: function(message){ alert(message); }
  });

  $("#image_cancel").click(reset_image);
  $("#use_facebook").click(use_facebook_image);
  $("#image_confirm").click(hide_cropper);

}


function uploadDone(filename) { //Function will be called when iframe is loaded
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
        setSelect:   [ 0, 0, 120, 120 ],
        aspect_ratio: 1
      });
    selected_pic = 1;
  });
  $("#shop_picturepreview").empty();
  $("#shop_picturepreview").append(im);
  im.attr("src", "/tmp_upload/"+crop_pictname);
  $("#preview").attr("src", "/tmp_upload/"+crop_pictname);
}

function reset_image(ev){
  if (ev)
    ev.preventDefault();
  $("#preview").attr("src",G_default_picture_url);
  $("#imageuploader").show();
  $("#picture_table").hide();
  $('#preview').css({
    width: 120 + 'px',
    height: '',
    marginLeft: '-' + 0 + 'px',
    marginTop: '-' + 0 + 'px'
  });
  //restore to default
  selected_pic = null;
}

function use_facebook_image(ev){
  if (ev) ev.preventDefault();
  $("#preview").attr("src",G_user_facebook_picture);
  $("#imageuploader").show();
  $("#picture_table").hide();
  $('#preview').attr({height: null, width: null})
  $('#preview').css({
    width: 120 + 'px',
    height: '',
    marginLeft: '-' + 0 + 'px',
    marginTop: '-' + 0 + 'px'
  });
  selected_pic = 0;
}

function hide_cropper(ev){
  if (ev) ev.preventDefault();
  $("#imageuploader").show();
  $("#picture_table").hide();
}

function showPreview(coords)
{
  var rx = 120 / coords.w;
  var ry = 120 / coords.h;

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



////////////////////////////////////////////////////
//
//  SAVE
//
////////////////////////////////////////////////////

function shop_edit_save(ev)
{
  if (ev) ev.preventDefault();

  window.onbeforeunload = null;

  diveboard.mask_file(true);

  //Push the form
  var data_to_send = {
    'id': G_shop_api['id'],
    'category': $(".shop_edit_structure .list_option.active").attr('name'),
    'address': $('#shopedit_address').val(),
    'city': $('#shopedit_city').val(),
    'country_code': $("#shopedit_country").attr('shortname'),
    'email': $('#shopedit_email').val(),
    'openings': $('#shopedit_openings').val(),
    'lat': diveboard.isNumeric($('#shopedit_lat').val()) ? $('#shopedit_lat').val() : null,
    'lng': diveboard.isNumeric($('#shopedit_lng').val()) ? $('#shopedit_lng').val() : null,
    'phone': $('#shopedit_phone').val(),
    'web': $('#shopedit_web').val(),
    'facebook': $('#shopedit_facebook').val(),
    'twitter': $('#shopedit_twitter').val(),
    'google_plus': $('#shopedit_google_plus').val()
  };

  try {
    data_to_send.nearby = $('#shop_edit_nearby').elrte('val');
  } catch(e){
    data_to_send.nearby = $('#shop_edit_nearby').html();
  }

  try {
    data_to_send.about_html = $('#shop_edit_about').elrte('val');
  } catch(e){
    data_to_send.about_html = $('#shop_edit_about').html();
  }


  //Only push the list of dives if the selection of favorite dives changed
  if (G_changed_dives){
    var fav_dives = [];
    $(".fav_dives_chk").each(function(index){
      var dive_id = this.name.replace(/.*_/, "");
      fav_dives.push( {'id': dive_id, 'favorite': this.checked} );
    });

    data_to_send['owned_dives'] = fav_dives;
  }

  //Only push the picture settings if the picture part has been touched
  if (typeof selected_pic != 'undefined' && selected_pic == 0) {
    data_to_send['crop_picture'] = {
      'selected_pic': selected_pic
    };
  }
  else if (typeof selected_pic != 'undefined' && selected_pic == 1) {
    data_to_send['crop_picture'] = {
      'selected_pic': selected_pic,
      'crop_width': crop_width,
      'crop_height': crop_height,
      'crop_mleft': crop_mleft,
      'crop_mright': crop_mright,
      'crop_pictname': crop_pictname,
      'crop_coords_w': crop_coords_w,
      'crop_coords_h': crop_coords_h,
      'crop_coords_x': crop_coords_x,
      'crop_coords_y': crop_coords_y,
    };
  }

  $.ajax({
    url: '/api/V2/shop',
    dataType: 'json',
    data: {
      arg: JSON.stringify(data_to_send),
      'authenticity_token': auth_token
    },
    type: "POST",
    success: function(data){
      if (data.success && (data.error == null||data.error.length==0)){
        window.location.replace(G_shop_api.permalink);
      } else if (data.success) {
        diveboard.alert(I18n.t(["js","shop_home","The data could not be completely updated"]), data, function(){
          window.location.replace(G_shop_api.permalink);
        });

      } else {
        //detail the alert
        diveboard.alert(I18n.t(["js","shop_home","A technical error occured."]), data, function(){
          diveboard.unmask_file();
        });
      }
    },
    error: function(data) {
      diveboard.alert(I18n.t(["js","shop_home","A technical error occured while saving the dive. Please make sure your internet connection is up and try again."]), null, function() {
        diveboard.unmask_file();
      });
    }
  });


}


////////////////////////////////////////////////////
//
//  REVIEW SPAM
//
////////////////////////////////////////////////////
function report_review_as_spam(review_id){
  $("#dialog-report-spam").dialog({
      resizable: false,
      modal: true,
      width: '700px',
      zIndex: 99999,
      buttons: {
        'Report as inappropriate': function(e){
          $("#dialog-report-spam").dialog('close');
          diveboard.mask_file(true);
          $.ajax({
            url: '/api/report_review',
            dataType: 'json',
            data: {
              id: review_id,
              'authenticity_token': auth_token
            },
            type: "POST",
            success: function(data){
              if (data.success){
                diveboard.unmask_file();
                diveboard.notify(I18n.t(["js","shop_home","Report inappropriate review"]), I18n.t(["js","shop_home","The review has been marked as inappropriate and will be checked by Diveboard team. Thanks for your submission."]));
              } else {
                //detail the alert
                diveboard.unmask_file();
                diveboard.alert(I18n.t(["js","shop_home","A technical error occured while reporting the review. You should retry after reloading the page. If it still fails, you may send us a mail to <a href='mailto:support@diveboard.com'>support@diveboard.com</a>"]), data, function(){});
              }
            },
            error: function(data) {
              diveboard.unmask_file();
              diveboard.alert(I18n.t(["js","shop_home","A technical error occured while reporting the review. You should retry after reloading the page. If it still fails, you may send us a mail to <a href='mailto:support@diveboard.com'>support@diveboard.com</a>"]), data, function(){});
            }

          });
        },
        'Cancel': function(e){
          $("#dialog-report-spam").dialog('close');
        }
      }
  });
}

////////////////////////////////////////////////////
//
//  REVIEW REPLY
//
////////////////////////////////////////////////////
function initialize_review_reply(){

  $('.leave_reply').live('click', function(ev){
    var review = $(this).closest('.review_body');
    review.find('.review_reply').hide();
    review.find('.review_reply_editor').show();
  });

  $('.review_reply_cancel').live('click', function(ev){
    var review = $(this).closest('.review_body');
    review.find('.review_reply').show();
    var editor = review.find('.review_reply_editor');
    editor.hide();
    var initial_text = review.find('.review_reply .reply_text').text();
    editor.find('.review_reply_edit').val(initial_text);
  });

  $('.review_reply_submit').live('click', function(ev){
    diveboard.mask_file(true);
    var review = $(this).closest('.review_body');
    var text = review.find('.review_reply_editor .review_reply_edit').val();
    var reply_id = review.find('.review_reply_editor .review_id').val();
    $.ajax({
      url: '/api/reply_review',
      dataType: 'json',
      data: {
        review_id: reply_id,
        reply: text,
        'authenticity_token': auth_token
      },
      type: "POST",
      success: function(data){
        if (data.success && (data.error == null||data.error.length==0)){
          window.location.replace(G_shop_api.permalink);
        } else if (data.success) {
          diveboard.alert(I18n.t(["js","shop_home","The data could not be completely updated"]), data, function(){
            window.location.replace(G_shop_api.permalink);
          });

        } else {
          //detail the alert
          diveboard.alert(I18n.t(["js","shop_home","A technical error occured."]), data, function(){
            diveboard.unmask_file();
          });
        }
      },
      error: function(data) {
        diveboard.alert(I18n.t(["js","shop_home","A technical error occured while saving the dive. Please make sure your internet connection is up and try again."]), null, function() {
          diveboard.unmask_file();
        });
      }
    });
  });


}







////////////////////////////////////////////////////
//
//  SHOP CLAIM
//
////////////////////////////////////////////////////

function initialize_shop_claim()
{
  //making sure it is only executed once
  if (initialize_shop_claim.already_initialized) return;
  else initialize_shop_claim.already_initialized = true

  $(".claim_shop_link").live('click', function(e){
    e.preventDefault();
    show_shop_claim();
  });

  $(".claim_shop_manual_link").live('click', function(e){
    e.preventDefault();
    $("#dialog-claim-shop .auto_claim").hide();
    $("#dialog-claim-shop .manual_claim").show();
  });

  $(".claim_shop_auto_link").live('click', function(e){
    e.preventDefault();
    $("#dialog-claim-shop .auto_claim").show();
    $("#dialog-claim-shop .manual_claim").hide();
  });

  $("#dialog_claim_auto_submit").live('click', function(e){
    e.preventDefault();
    shop_claim_mail();
  });

  $("#dialog_claim_explanation_submit").live('click', function(e){
    e.preventDefault();
    shop_claim_explain();
  });

  $("#shop_validate_claim").live('click', function(e){
    e.preventDefault();
    shop_claim_valid();
  });
}

function show_shop_claim()
{
  $("#dialog-claim-shop").dialog({
      resizable: false,
      modal: true,
      width: '700px',
      zIndex: 99999,
      buttons: {
        'Cancel': function(){ $("#dialog-claim-shop").dialog('close'); }
      }
  });
  if (G_shop_api.email) {
    $("#dialog-claim-shop .auto_claim").show();
    $("#dialog-claim-shop .manual_claim").hide();
  } else {
    $("#dialog-claim-shop .auto_claim").hide();
    $("#dialog-claim-shop .manual_claim").show();
  }
}

function shop_claim_mail()
{
  diveboard.mask_file(true);
  $("#dialog-claim-shop").dialog('close');

  $.ajax({
    url: '/api/shop/claim_mail',
    dataType: 'json',
    data: {
      'group_id': G_owner_api['id'],
      'authenticity_token': auth_token
    },
    type: "POST",
    success: function(data){
      if (data.success && (data.error == null||data.error.length==0)){
        diveboard.notify(I18n.t(["js","shop_home","Get access"]),I18n.t(["js","shop_home","A mail has been sent with a link to validate the claim."]), function(){
          window.location.replace(G_shop_api.permalink);
        });
      } else if (data.success) {
        diveboard.alert(I18n.t(["js","shop_home","The request could not be processed. Please try again or leave us a message for your claim."]), data, function(){
          window.location.replace(G_shop_api.permalink);
        });

      } else {
        //detail the alert
        diveboard.alert(I18n.t(["js","shop_home","A technical error occured and the request could not be processed. Please try again or leave us a message for your claim."]), data, function(){
          diveboard.unmask_file();
        });
      }
    },
    error: function(data) {
      diveboard.alert(I18n.t(["js","shop_home","A technical error occured while saving the dive. Please make sure your internet connection iIf it still doesn't work, leave us a message for your claim."]), null, function() {
        diveboard.unmask_file();
      });
    }
  });
}

function shop_claim_explain()
{
  diveboard.mask_file(true);
  $("#dialog-claim-shop").dialog('close');

  $.ajax({
    url: '/api/shop/claim_explain',
    dataType: 'json',
    data: {
      'group_id': G_owner_api['id'],
      'explanation': $("#dialog_claim_explanation").val(),
      'authenticity_token': auth_token
    },
    type: "POST",
    success: function(data){
      if (data.success && (data.error == null||data.error.length==0)){
        diveboard.notify(I18n.t(["js","shop_home","Get access"]),I18n.t(["js","shop_home","Your request has been transmitted to Diveboard support. You should get some feedback within the next few days !"]), function(){
          window.location.replace(G_shop_api.permalink);
        });
      } else if (data.success) {
        diveboard.alert(I18n.t(["js","shop_home","The data could not be completely updated"]), data, function(){
          window.location.replace(G_shop_api.permalink);
        });

      } else {
        //detail the alert
        diveboard.alert(I18n.t(["js","shop_home","A technical error occured."]), data, function(){
          diveboard.unmask_file();
        });
      }
    },
    error: function(data) {
      diveboard.alert(I18n.t(["js","shop_home","A technical error occured while saving the dive. Please make sure your internet connection is up and try again."]), null, function() {
        diveboard.unmask_file();
      });
    }
  });
}

function shop_claim_valid()
{
  diveboard.mask_file(true);

  $.ajax({
    url: '/api/shop/claim_valid',
    dataType: 'json',
    data: {
      'c': $("#shop_validate_claim_string").val(),
      'authenticity_token': auth_token
    },
    type: "POST",
    success: function(data){
      if (data.success && (data.error == null||data.error.length==0)){
        var nickname = $("#shop_validate_claim_nickname").val();
        diveboard.notify(I18n.t(["js","shop_home","Get access"]),I18n.t(["js","shop_home","The validation has been correctly taken into account. %{nickname} now has the right to edit the page <a href='%{permalink}/edit/welcome?success=true' target=_blank>%{permalink}</a>"], {nickname:nickname, permalink: G_shop_api['permalink']}), function(){
          window.location.replace(G_shop_api.permalink+'/edit/welcome?success=true');
        });
      } else if (data.success) {
        diveboard.alert(I18n.t(["js","shop_home","The validation has failed."]), data, function(){
          window.location.replace(G_shop_api.permalink);
        });

      } else {
        //detail the alert
        diveboard.alert(I18n.t(["js","shop_home","A technical error occured."]), data, function(){
          diveboard.unmask_file();
        });
      }
    },
    error: function(data) {
      diveboard.alert(I18n.t(["js","shop_home","A technical error occured while saving the dive. Please make sure your internet connection is up and try again."]), null, function() {
        diveboard.unmask_file();
      });
    }
  });
}


//////////////////////
//
// ADVERTISEMENT
//
//////////////////////
function initialize_ad(){
  $(".ad_item_title_input, .ad_item_content_input").live('change', function(){
    update_preview_ad($(this).closest('.ad_item_editor'));
  });
  $(".ad_item_title_input, .ad_item_content_input").live('keypress', function(){
    update_preview_ad($(this).closest('.ad_item_editor'));
  });
  $(".ad_item_external_url").live('keypress', function(){
    $(this).closest('.ad_item_editor').find('.ad_item_external_url_selected')[0].checked=true;
    update_preview_ad($(this).closest('.ad_item_editor'));
  });
  $(".ad_item_external_url_selected, .ad_item_external_url_unselected").live('click', function(){
    update_preview_ad($(this).closest('.ad_item_editor'));
  });
  $(".ad_item_create").live('click', create_ad);
  $(".ad_item_modify").live('click', function(i,e){
    display_editor_ad($(this).closest('.ad_item_row').data('ad_detail'));
  });
  $(".ad_item_reset").live('click', function(){
    reset_ad($(this).closest('.ad_item_editor').data('ad_detail'));
  });
  $(".ad_item_submit").live('click', function(){
    submit_ad($(this).closest('.ad_item_editor'));
  });
  $('.ad_item_cancel').live('click', function(){
    $('#dialog-edit-ad').dialog('close');
  });

  $(".ad_item_hold").live('click', function(){
    hold_ad($(this).closest('.ad_item_row').data('ad_detail'));
  });
  $(".ad_item_delete").live('click', function(){
    delete_ad($(this).closest('.ad_item_row').data('ad_detail'));
  });
  $(".ad_item_reactivate").live('click', function(){
    reactivate_ad($(this).closest('.ad_item_row').data('ad_detail'));
  });
  $(".edit_ad_picture_option").live('click', function(){
    var img = $(this).data('picture_detail');
    var form = $(this).closest('#dialog-edit-ad').find('.ad_item_editor');
    form.find('.ad_item_pictid_input').val(img.id);
    form.find('.ad_item_thumbnail_input').val(img.thumbnail);
    update_preview_ad(form);
  });

  $(".ad_item_editor button").live('click', function(e){e.preventDefault(); });

  display_list_ad();

  crop_upload_api_ad = diveboard.setup_crop_upload({
    selector:"#dialog-edit-ad",
    user_id: G_user_proxy_api.id,
    crop:true,
    box_width: 300,
    preview: null,
    cancel: function(){},
    confirm: function(api){
      api.reset();
      $('#dialog-edit-ad .edit_ad_pictures_container').prepend("<img src='/img/transparent_loader_2.gif' style='margin:22px'/>");
      var crop = api.tellSelect();
      $.ajax({
        url: '/api/picture/upload',
        data: {
          user_id: G_user_proxy_api.id,
          from_tmp_file: api.getPictname(),
          crop_x0: crop.x,
          crop_y0: crop.y,
          crop_width: crop.w,
          crop_height: crop.h,
          album: G_user_proxy_api.ad_album_id,
          flavour: 'private',
          'authenticity_token': auth_token
        },
        dataType: "json",
        success: function(data){
          if (data.success) {
            G_ad_pictures.push(data.result);
            display_editor_picture_ad();
            var form = $('#dialog-edit-ad').find('.ad_item_editor');
            form.find('.ad_item_pictid_input').val(data.result.id);
            form.find('.ad_item_thumbnail_input').val(data.result.thumbnail);
            update_preview_ad(form);
          } else {
            diveboard.alert(I18n.t(["js","shop_home","A technical error occured while cropping the picture"]), data);
          }
        },
        error: function(data){
          diveboard.alert(I18n.t(["js","shop_home","A technical error occured while cropping the picture"]), data);
        }
      });
    }
  });
}


function display_list_ad(){
  $("#ad_list").html('');
  var sorted_list = G_user_proxy_api.advertisements.sort(function(a,b){return(
    ((a.ended_at?1:0) - (b.ended_at?1:0)) || ( new Date(b.created_at) - new Date(a.created_at) )
    )});
  for (var id in sorted_list) {
    var ad = $.extend({}, sorted_list[id]);
    ad.actions = {
      modify: true,
      del: ad.ended_at!=null,
      reactivate: ad.ended_at!=null,
      hold: ad.ended_at==null
    };

    var line = $(JST['ads/_ad_list_row']({ad:ad}));
    line.data('ad_detail', sorted_list[id]);
    line.find('.ad_item_preview').html(JST['ads/_explore_advertisement'](ad));

    $("#ad_list").append(line);
  }
}

function display_editor_ad(ad_detail){
  reset_ad(ad_detail);
  display_editor_picture_ad();
  $('#dialog-edit-ad').dialog({
    resizable: false,
    modal: true,
    width: '700px',
    zIndex: 99999,
    buttons: {}
  });
}

function display_editor_picture_ad(){
  var container = $("#dialog-edit-ad .edit_ad_pictures_container");
  container.html('');
  $.each(G_ad_pictures.reverse(), function(i,e){
    var img = $("<img src='"+ e.thumbnail +"' class='edit_ad_picture_option'/>");
    img.data('picture_detail', e);
    container.append(img);
  });
}

function refresh_user_api(callback){
  diveboard.api_call('user', {id: G_user_proxy_api.id}, function(data){
      G_user_proxy_api = data.result;
      if (callback)
        callback(data);
    },
    function(){},
    'private');
}

function create_ad(){

  if (G_shop_api.allowed_ads && count_active_ads() >= G_shop_api.allowed_ads){
    //diveboard.notify(I18n.t(["js","shop_home","Create new ad"]), I18n.t(["js","shop_home","You have reached the maximum of %{max}. Please delete or put on hold an existing ad to create a new one."], {max: G_shop_api.allowed_ads}));
    return;
  }

  display_editor_ad({
    id: null,
    picture_id: null,
    external_url: null,
    shop_permalink: G_shop_api.permalink,
    user_id: G_user_proxy_api.id,
    title: I18n.t(["js","shop_home","Ad title"]),
    text: I18n.t(["js","shop_home","Content"]),
    thumbnail: '/img/no_picture.png'
  });
}

function hold_ad(ad_detail){
  var data_to_send = {
    id: ad_detail.id,
    ended_at: true
  };

  diveboard.mask_file(true);

  diveboard.api_call('advertisement', data_to_send,
    function(data){
      refresh_user_api(function(){
        display_list_ad();
        diveboard.unmask_file();
      });
    },
    function(data){
      refresh_user_api(function(){
        display_list_ad();
        diveboard.unmask_file();
      });
    },
    'private');
}

function delete_ad(ad_detail){
  diveboard.mask_file(true);
  diveboard.api_call_delete('advertisement', ad_detail.id,
    function(data){
      refresh_user_api(function(){
        display_list_ad();
        diveboard.unmask_file();
      });
    },
    function(data){
      refresh_user_api(function(){
        display_list_ad();
        diveboard.unmask_file();
      });
    });
}

function reactivate_ad(ad_detail){
  var new_ad = $.extend({},ad_detail);
  delete new_ad.id;
  delete new_ad.ended_at;
  delete new_ad.deleted;

  var data_to_send = [{
    id: ad_detail.id,
    deleted: true
  }, new_ad];

  $('#dialog-edit-ad').dialog('close');
  diveboard.mask_file(true);

  diveboard.api_call('advertisement', data_to_send,
    function(data){
      refresh_user_api(function(){
        display_list_ad();
        diveboard.unmask_file();
      });
    },
    function(data){
      refresh_user_api(function(){
        display_list_ad();
        diveboard.unmask_file();
      });
    },
    'private');
}




function update_preview_ad(ad_item_editor_element){
  if (diveboard.postpone_me(500)) return;

  var ad = $.extend({}, ad_item_editor_element.data('ad_detail'));

  ad.title = ad_item_editor_element.find('.ad_item_title_input').val();
  ad.text = ad_item_editor_element.find('.ad_item_content_input').val();
  ad.thumbnail = ad_item_editor_element.find('.ad_item_thumbnail_input').val();

  if (ad_item_editor_element.find('.ad_item_external_url_selected')[0].checked) {
    ad.external_url = ad_item_editor_element.find('.ad_item_external_url').val();
    if (!ad.external_url.match(/^(http|https|ftp):\/\//) && ad.external_url.length > 3)
      ad.external_url = "http://"+ad.external_url
  }
  else
    ad.external_url = null;

  ad_item_editor_element.find('.ad_item_preview').html( JST['ads/_explore_advertisement'](ad));
}

function reset_ad(ad_detail){
  var content = $(JST['ads/_ad_item_editor'](ad_detail));
  content.data('ad_detail', ad_detail);
  content.find('.ad_item_preview').html( JST['ads/_explore_advertisement']( ad_detail));
  var container = $('#dialog-edit-ad .edit_ad_container');
  container.html('');
  container.append(content);
}

function submit_ad(element){
  var data_to_send = $.extend({}, element.data('ad_detail'));
  data_to_send.title = element.find('.ad_item_title_input').val();
  data_to_send.text = element.find('.ad_item_content_input').val();
  if (element.find('.ad_item_external_url_selected')[0].checked) {
    data_to_send.external_url = element.find('.ad_item_external_url').val();
    if (!data_to_send.external_url.match(/^(http|https|ftp):\/\//) && data_to_send.external_url.length > 3)
      data_to_send.external_url = "http://"+data_to_send.external_url
  }
  else
    data_to_send.external_url = null;
  data_to_send.picture_id = element.find('.ad_item_pictid_input').val();

  if (!validate_ad(data_to_send))
    return;

  $('#dialog-edit-ad').dialog('close');
  diveboard.mask_file(true);

  diveboard.api_call('advertisement', data_to_send,
    function(data){
      refresh_user_api(function(){
        display_list_ad();
        diveboard.unmask_file();
      });
    }, function(data){
      refresh_user_api(function(){
        display_list_ad();
        diveboard.unmask_file();
      });
    }, 'private');
}

function validate_ad(data){
  if (!data.title || data.title.length < 10) {
    diveboard.notify(I18n.t(["js","shop_home","Validation"]), I18n.t(["js","shop_home","The title must be at least 10 caracters long."]));
    return false;
  }
  if (data.title.length > 25) {
    diveboard.notify(I18n.t(["js","shop_home","Validation"]), I18n.t(["js","shop_home","The title cannot be more than 25 caracters long."]));
    return false;
  }
  if (!data.text || data.text.length < 10) {
    diveboard.notify(I18n.t(["js","shop_home","Validation"]), I18n.t(["js","shop_home","The content must be at least 10 caracters long."]));
    return false;
  }
  if (data.text.length > 90) {
    diveboard.notify(I18n.t(["js","shop_home","Validation"]), I18n.t(["js","shop_home","The content cannot be more than 90 caracters long."]));
    return false;
  }
  if (!data.picture_id) {
    diveboard.notify(I18n.t(["js","shop_home","Validation"]), I18n.t(["js","shop_home","You must select or upload a picture to create an ad."]));
    return false;
  }
  if (!data.user_id){
    diveboard.alert(I18n.t(["js","shop_home","Technical error : a user identifier must be provided."]));
    return false;
  }
  if (data.external_url != null && data.external_url.length < 3 ){
    diveboard.alert(I18n.t(["js","shop_home","Please check the external url provided : it should normally be at least 3 caracters long."]));
    return false;
  }

  return true;
}

function count_active_ads()
{
  var count = 0;
  for (var i in G_user_proxy_api.advertisements) {
    var ad = G_user_proxy_api.advertisements[i];
    if (!ad.deleted && !ad.ended_at)
      count++;
  }
  return(count);
}



