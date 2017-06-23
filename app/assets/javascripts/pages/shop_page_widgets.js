//
// Widget class
//

Widget = function(){}

Widget.init = function(elt){
  var widget_class=elt.attr('data-widget_class');
  var widget_id=elt.attr('data-widget_id');
  var mode=elt.attr('data-mode');

  try {
    if($(elt).data('widget_object') == undefined){
      var object = new window[widget_class](elt);
    }else{
      var object = $(elt).data('widget_object');
    }
    if(!object.is_initialized()){
      elt.data('widget_object', object);
      var init_func = ""+mode+"_init";
      if (object[init_func]){
        object[init_func]();
      } else if (object.init){
        object.init()
      }
    }
  } catch(e){
    if (e.message)
      console.error(e.message);
    if (e.stack)
      console.log(e.stack);
    console.log(widget_class)
  }
}




//
//
// Widget Picture Banner init
//
//

function WidgetPictureBanner(dom){
  //this part is run when new is called
  this.element = $(dom);
  this.element.data('widget_object',this);
  this.initialized = false;
}

WidgetPictureBanner.prototype.is_initialized = function(){
  return this.initialized;
}

WidgetPictureBanner.prototype.view_init = function(){
  console.log("view init");
  if(this.element.find("img").length >1 ){
    this.element.find(".slides").slides({
          preload: true,
          preloadImage: '/img/transparent_loader_2.gif',
          play: 5000,
          pause: 2500,
          hoverPause: true
        });
  }
  this.initialized = true;
}
WidgetPictureBanner.prototype.remove_image = function(e){
  e.preventDefault();
  $(e.target).parent().remove();
}

WidgetPictureBanner.prototype.edit_init = function(){
  this.initial_picture_list = this.get_pictures_id();
  var me = this;
  me.element.find(".banners_container ul").sortable();
  me.element.find(".delete_image_widget_picture_banner").click(this.remove_image);

  if (!me.element.attr("id"))
    me.element.attr("id", "widget_picture_banner_"+Date.now());

  crop_upload_api_ad = diveboard.setup_crop_upload({
    selector: "#"+me.element.attr("id"),
    user_id: G_owner_api.id,
    crop:true,
    box_width: 800,
    aspect_ratio: 4,
    preview: null,
    cancel: function(){},
    confirm: function(api){
      api.reset();
      me.element.find('.banners_container').show();
      me.element.find(".banners_container ul").sortable("disable");
      me.element.find('.banners_container ul').append("<li><img src='/img/transparent_loader_2.gif' style='margin:5px 22px'/><span class='symbol delete_image_widget_picture_banner' style='display:none;'>'</span></li>");
      var crop = api.tellSelect();
      $.ajax({
        url: '/api/picture/upload',
        data: {
          user_id: G_owner_api.id,
          from_tmp_file: api.getPictname(),
          crop_x0: crop.x,
          crop_y0: crop.y,
          crop_width: crop.w,
          crop_height: crop.h,
          flavour: 'private',
          'authenticity_token': auth_token
        },
        dataType: "json",
        success: function(data){
          if (data.success) {
            me.element.find('.banners_container ul li img').last().attr("src", data.picture.image).attr("data-image_id", data.picture.id).attr("width", 800);
            me.element.find('.banners_container ul li span').last().show().click(me.remove_image);
            me.element.find(".banners_container ul").sortable("refresh");
            me.element.find(".banners_container ul").sortable("enable");
          } else {
            diveboard.alert(I18n.t(["js","shop_page_widgets","A technical error occured while cropping the picture"]), data);
          }
        },
        error: function(data){
          diveboard.alert(I18n.t(["js","shop_page_widgets","A technical error occured while cropping the picture"]), data);
        }
      });
    }
  });

  this.initialized = true;
}

WidgetPictureBanner.prototype.get_pictures_id = function(){
  return $.map(
      this.element.find('.banners_container ul li img'),
      function(e){return Number($(e).attr("data-image_id"));}
      );
}

WidgetPictureBanner.prototype.has_changed = function(){
  return this.get_pictures_id() != this.initial_picture_list;
}


WidgetPictureBanner.prototype.data_for_save = function(){
  return {content: this.get_pictures_id()}
}
//
//
// Widget Text edit
//
//

function WidgetText(dom){
  //this part is run when new is called
  this.element = $(dom);
  this.flag_changed = false;
  this.initial_html = null;
  this.initialized = false;
}

WidgetText.prototype.is_initialized = function(){
  return this.initialized;
}


WidgetText.prototype.edit_init = function() {
  //modal text editor used throughout diveboard to edit texts
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

  this.element.find('.textedit').elrte(opts);
  this.initial_html = this.element.find('.textedit').elrte('val');
  this.initialized = true;
}
WidgetText.prototype.view_init = function() {
  this.initialized = true;
}

WidgetText.prototype.has_changed = function(){
  if (this.initial_html == null) return(false);
  var html = this.element.find('.textedit').elrte('val');
  if (this.initial_html == html) this.flag_changed = false;
  else this.flag_changed = true;
  return(this.flag_changed);
}

WidgetText.prototype.data_for_save = function(){
  return {
    content: this.element.find('.textedit').elrte('val').toString()
  }
}

WidgetText.prototype.refresh = function(){
  var opts = {
          cssClass : 'el-rte',
          lang     : I18n.locale,
          height   : 400,
          toolbar  : 'diveboardtoolbar',
          cssfiles : ['/mod/elrte/css/elrte-inner.css']
        }

  var src = this.element.find('.textedit').elrte('val');
  this.element.find('.textedit').detach();
  this.element.find('.el-rte').detach();
  var new_edit = $("<div class='textedit'></div>").html(src);
  this.element.append(new_edit);
  new_edit.elrte(opts);
  console.log(new_edit.elrte('val'));
}

//
//
// Widget SAMPLE
// Sample structure for a widget - to be copy pasted :)
//
//

function WidgetSample(dom){
  //this part is run when new is called
  this.element = $(dom);
  this.initialized = false;
  if (!this.constructor.is_class_initialized && this.constructor.classInitialize)
    this.constructor.classInitialize();
}

WidgetSample.classInitialize = function(){
  this.is_class_initialized = true;
  //this code is run at most once, whatever the number of this kind of widgets on the page
}


WidgetSample.prototype.is_initialized = function(){
  return this.initialized;
  //prevents dom from being multi-initialized
}


WidgetSample.prototype.view_init = function(){
  this.initialized = true;
  //inits the view dom
}

WidgetSample.prototype.edit_init = function(){
  this.initialized = true;
  //inits the edit dom
}

WidgetSample.prototype.has_changed = function(){
  //tells the global save wether there is anything to do here
}

WidgetSample.prototype.data_for_save = function(){
  //returns hash with data to be saved by the widget's model
}

WidgetSample.prototype.save = function(){
  //does the save by himself
}


//
//
// Widget Admin
//
//

function WidgetProfile(dom){
  //this part is run when new is called
  this.element = $(dom);
  this.element.data('widget_object',this);
  this.initialized = false;
  this.initial_data = {};
  if (!this.constructor.is_class_initialized && this.constructor.classInitialize)
    this.constructor.classInitialize();
}

WidgetProfile.prototype.is_initialized = function(){
  return this.initialized;
}

WidgetProfile.classInitialize = function(){
  this.is_class_initialized = true;
  //this code is run at most once, whatever the number of this kind of widgets on the page
  initialize_shop_claim();
}

WidgetProfile.prototype.view_init = function(){
  //console.log("profile init");
  if (diveboard.postpone_me_load()) return;
  //console.log("profile init2");
  if($("#map_location_holder").length > 0){
    var lat = diveboard.isNumeric( G_shop_api['lat'] )? G_shop_api['lat'] : 0;
    var lng = diveboard.isNumeric( G_shop_api['lng'] )? G_shop_api['lng'] : 0;
    var zoom = 11;
    var position= {
      'height': ($("#contact_info_holder").position().top+$("#contact_info_holder").height())+"px",
      'width': ($("#shop_profile_data").width() -$("#contact_info_holder").width())+"px",
      'left' : $("#contact_info_holder").width()+"px"
    };
    $("#map_location_holder").css(position);

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
        streetViewControl: false,
        zoomControl: true,
        zoomControlOptions: {
          style: google.maps.ZoomControlStyle.LARGE,
          position: google.maps.ControlPosition.LEFT_CENTER
        }
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



  this.initialized = true;
}

WidgetProfile.prototype.edit_init = function(){
  var me = this;
  this.initial_data = this.extract_data();

  if (!me.element.attr("id"))
    me.element.attr("id", "widget_picture_banner_"+Date.now());

  crop_upload_api_ad = diveboard.setup_crop_upload({
    selector: "#"+me.element.attr("id"),
    user_id: G_owner_api.id,
    crop:true,
    box_width: 400,
    aspect_ratio: 1,
    preview: null,
    cancel: function(){},
    confirm: function(api){
      api.reset();
      me.element.find('.current_image img').attr("src", "/img/transparent_loader_2.gif").attr("data-image_id", "");
      var crop = api.tellSelect();
      $.ajax({
        url: '/api/picture/upload',
        data: {
          user_id: G_owner_api.id,
          from_tmp_file: api.getPictname(),
          crop_x0: crop.x,
          crop_y0: crop.y,
          crop_width: crop.w,
          crop_height: crop.h,
          flavour: 'private',
          'authenticity_token': auth_token
        },
        dataType: "json",
        success: function(data){
          if (data.success) {
            me.element.find('.current_image img').attr("src", data.picture.image).attr("data-image_id", data.picture.id);
          } else {
            diveboard.alert(I18n.t(["js","shop_page_widgets","A technical error occured while cropping the picture"]), data);
          }
        },
        error: function(data){
          diveboard.alert(I18n.t(["js","shop_page_widgets","A technical error occured while cropping the picture"]), data);
        }
      });
    }
  });

  this.initialize_map_editor();
  this.initialize_text_editor();

  this.element.find(".autocomplete_country input").removeClass('ui-autocomplete-input');
  this.element.find(".autocomplete_country input").addClass('ui-autocomplete-input example');

  this.element.find(".autocomplete_country input").autocomplete({  source : countries,
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

  this.element.find('.save_buttons .save').click(function(){
    me.save();
  });

  this.initialized = true;
}

WidgetProfile.prototype.has_changed = function(){
  if(Number(this.element.find('.current_image img').attr("data-image_id")) != 0 && !isNaN(Number(this.element.find('.current_image img').attr("data-image_id"))))
    return true;
  else
    return false;
}


WidgetProfile.prototype.data_for_save = function(){
  data = {}
  if(Number(this.element.find('.current_image img').attr("data-image_id")) != 0 && !isNaN(Number(this.element.find('.current_image img').attr("data-image_id"))))
    data["profile_picture_id"] = Number(this.element.find('.current_image img').attr("data-image_id"));

  return {content: data}
}

WidgetProfile.prototype.initialize_map_editor = function(){
  if (!this.element.find("#shopedit_gmap").is(':visible'))
    return;
  var me = this;
  var lat, lng, zoom, show_shop_pin;

  if (!diveboard.isNumeric(this.element.find("#shopedit_lat").val()) || !diveboard.isNumeric(this.element.find("#shopedit_lng").val()) ){
    lat = 0;
    lng = 0;
    zoom = 1;
    show_shop_pin = false;
  } else {
    lat = this.element.find("#shopedit_lat").val();
    lng = this.element.find("#shopedit_lng").val();
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
      me.element.find("#shopedit_lat").val(lat);
      me.element.find("#shopedit_lng").val(lng);
    });

    this.element.find("#shopedit_lat, #shopedit_lng").live('change', function(){
      var lat = parseFloat(me.element.find("#shopedit_lat").val());
      var lng = parseFloat(me.element.find("#shopedit_lng").val());
      if ( diveboard.isNumeric(me.element.find("#shopedit_lat").val()) && diveboard.isNumeric(me.element.find("#shopedit_lng").val()) ) {
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

    this.element.find("#shopedit_gmap_placepin").live('click', function(){
      var center = map.getCenter();
      marker.setPosition(center);
      me.element.find("#shopedit_lat").val(center.lat());
      me.element.find("#shopedit_lng").val(center.lng());
      marker.setVisible(true);
      place_pin_button.hide();
    });

    var place_pin_button = this.element.find("#shopedit_gmap_placepin").detach();
    place_pin_button.css('margin', '10px');
    map.controls[google.maps.ControlPosition.TOP_RIGHT].push(place_pin_button[0]);
    if (show_shop_pin) place_pin_button.hide();
    else place_pin_button.show();

  } catch(e){
    if (console && console.log)
      console.log(e.message)
  }
}

WidgetProfile.prototype.initialize_shop_location_map = function() {
  var me = this;
  var lat = diveboard.isNumeric( G_shop_api['lat'] )? G_shop_api['lat'] : 0;
  var lng = diveboard.isNumeric( G_shop_api['lng'] )? G_shop_api['lng'] : 0;


  var zoom = 11;

  if (initialize_shop_location_map.initialized) return;
  if (!this.element.find("#map_location_holder").is(":visible")) return;
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

WidgetProfile.prototype.initialize_text_editor = function() {
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

  this.element.find('#shop_edit_nearby:visible').elrte(opts);
}


WidgetProfile.prototype.extract_data = function(doall){
  var current_data = {
    'name': this.element.find("#shopedit_name").val(),
    'category': this.element.find("#shop_type").val(),
    'address': this.element.find('#shopedit_address').val(),
    'city': this.element.find('#shopedit_city').val(),
    'country_code': this.element.find("#shopedit_country").attr('shortname'),
    'email': this.element.find('#shopedit_email').val(),
    'openings': this.element.find('#shopedit_openings').val(),
    'lat': diveboard.isNumeric(this.element.find('#shopedit_lat').val()) ? this.element.find('#shopedit_lat').val() : null,
    'lng': diveboard.isNumeric(this.element.find('#shopedit_lng').val()) ? this.element.find('#shopedit_lng').val() : null,
    'phone': this.element.find('#shopedit_phone').val(),
    'web': this.element.find('#shopedit_web').val(),
    'facebook': this.element.find('#shopedit_facebook').val(),
    'twitter': this.element.find('#shopedit_twitter').val(),
    'google_plus': this.element.find('#shopedit_google_plus').val()
  };

  try {
    current_data.nearby = this.element.find('#shop_edit_nearby').elrte('val');
  } catch(e){
    current_data.nearby = this.element.find('#shop_edit_nearby').html();
  }

  //Only push the picture settings if the picture part has been touched
  if (typeof this.element.find('.current_image img').attr("data-image_id") != 'undefined') {
    current_data['crop_picture'] = {
      'picture_id': Number(this.element.find('.current_image img').attr("data-image_id"))
    };
  }

  if (doall == undefined || doall != true)
    var cleaned_data= diveboard.extract_changed_data(this.initial_data, current_data);
  else
    var cleaned_data = current_data;

  cleaned_data['id'] =G_shop_api['id'];

  return cleaned_data;
}

WidgetProfile.prototype.save = function() {

//  window.onbeforeunload = null;
  var me = this;
  diveboard.mask_file(true);
  var new_data = this.extract_data();
  //Push the form


  $.ajax({
    url: '/api/V2/shop',
    dataType: 'json',
    data: {
      arg: JSON.stringify(new_data),
      'authenticity_token': auth_token
    },
    type: "POST",
    success: function(data){
      if (data.success && (data.error == null||data.error.length==0)){
        diveboard.unmask_file();
        if(typeof me.element.find('.current_image img').attr("data-image_id") != 'undefined'){
          $(".head_picture").attr("src", me.element.find('.current_image img').attr("src"));
          me.element.find('.current_image img').attr("data-image_id", undefined);
        }
        if (new_data.category != undefined){
          $(".head_category").html(new_data.category);
        }
        if (new_data.name != undefined){
          $(".header_title").html(new_data.name);
        }
        if (new_data.country_code != undefined){
          $(".head_title img").attr("src", "/img/flags/"+new_data.country_code.toLowerCase()+".gif");
        }
        //save the new dataset
        me.initial_data = me.extract_data(true);
        //window.location.replace('/'+G_shop_api['vanity_url']);
      } else if (data.success) {
        diveboard.alert(I18n.t(["js","shop_page_widgets","The data could not be completely updated"]), data, function(){
        diveboard.unmask_file();
        //window.location.replace('/'+G_shop_api['vanity_url']);
        });
      } else {
        //detail the alert
        diveboard.alert(I18n.t(["js","shop_page_widgets","A technical error occured."]), data, function(){
          diveboard.unmask_file();
        });
      }
    },
    error: function(data) {
      diveboard.alert(I18n.t(["js","shop_page_widgets","A technical error occured while saving the dive. Please make sure your internet connection is up and try again."]), null, function() {
        diveboard.unmask_file();
      });
    }
  });


}





// Dive List editor
function WidgetSpreadsheet(dom){
  //this part is run when new is called
  this.element = $(dom);
  this.initialized = false;
  this.has_changed = false;
  if (!this.constructor.is_class_initialized && this.constructor.classInitialize)
    this.constructor.classInitialize();
}

WidgetSpreadsheet.classInitialize = function(){
}

WidgetSpreadsheet.prototype.is_initialized = function(){
  //We always want to reinit when changing tabs
  return false;
}

WidgetSpreadsheet.prototype.has_changed = function(){
  return this.has_changed;
}


WidgetSpreadsheet.prototype.edit_init = function(){
  if (!this.initialized) {
    this.reset();
    this.initialized = true;

    var me=this;
    this.element.find('.save_dive_price_list').bind('click', function(){
      me.save();
    });
    this.element.find('.reset_dive_price_list').bind('click', function(){
      me.reset();
      me.edit_init()
    });
  }


  var me = this;
  var dom = this.element.find(".dive_list_edit");
  var handsontable_id = 0;
  if (dom.attr('id')== null) {
    while($("#handsontable_"+(++handsontable_id)).length > 0) {}
    dom.attr('id', "handsontable_"+handsontable_id);
  }
  dom.handsontable({
    data: this.local_data,
    colHeaders: [I18n.t(["js","shop_page_widgets","Category"]), I18n.t(["js","shop_page_widgets","Title"]), I18n.t(["js","shop_page_widgets","Description"]), I18n.t(["js","shop_page_widgets","Price"]), I18n.t(["js","shop_page_widgets","Tax (%)"]), I18n.t(["js","shop_page_widgets","Total price"]), "", "", I18n.t(["js","shop_page_widgets","Move"]), ""],
    minRows: 5,
    minSpareRows: 1,
    stretchH: 'all',
    scrollable: false,
    colWidths: [120, 200, 150, 80, 80, 80, 20, 35, 50, 50 ],
    autoWrapRow: false,
    autoWrapCol: false,
    manualColumnResize: true,
    contextMenu: ['row_above', 'row_below', 'remove_row','hsep1', 'undo', 'redo'],
    dataSchema: {
      hasChanged: null,
      shop_id: G_shop_api.id,
      realm: 'dive',
      currency: G_shop_api.currency,
      tax: null,
      currency_symbol: G_shop_api.currency_symbol
    },
    onBeforeChange: function (data) {
      for (var i = data.length - 1; i >= 0; i--) {
        var row = data[i][0];
        if (['price', 'tax', 'total'].indexOf(data[i][1])>=0 && !diveboard.isNumeric(data[i][3]) ) {
          data.splice(i, 1); //gently don't accept text
        }
      }
    },
    onChange: function(data, source){
      if (source == 'loadData') return;
      if (data.length == 0) return;
      for (var i = data.length - 1; i >= 0; i--) {
        var row = data[i][0];

        //Default values
        try {
          if (data[i][1] != 'tax' && me.local_data[row].tax == null)
            for (var cur = row-1;cur >=0 && me.local_data[row].tax == null; cur--)
              me.local_data[row].tax = me.local_data[cur].tax
        } catch(e){}

        //Calculates prices with/without tax on change
        if (data[i][3]) {
          if (data[i][1] == 'price'|| (diveboard.isNumeric(me.local_data[row].price) && data[i][1] == 'tax')){
            if (diveboard.isNumeric(me.local_data[row].price) && diveboard.isNumeric(me.local_data[row].tax))
              me.local_data[row].total = Math.round(100*me.local_data[row].price * (1+me.local_data[row].tax/100))/100;
            else
              me.local_data[row].total = '';
          }
          else
            if (diveboard.isNumeric(me.local_data[row].total) && diveboard.isNumeric(me.local_data[row].tax))
              me.local_data[row].price = Math.round(100*me.local_data[row].total / (1+me.local_data[row].tax/100))/100;
            else
              me.local_data[row].price = '';
        }

        if (data[i][2] !== data[i][3])
          me.local_data[row].hasChanged = true;

        //Making sure currency is not changed
        me.local_data[row].currency = G_shop_api.currency
        me.local_data[row].currency_symbol = G_shop_api.currency_symbol
      }
      me.has_changed = true;
      dom.handsontable('render');
    },
    columns: [
      {data: "cat1", type: {renderer: WidgetSpreadsheet.ColoredAutocompleteCellRenderer, editor: Handsontable.AutocompleteCell.editor}, source: G_dive_categories1 },
      {data: "title"},
      {data: "description", type: {renderer: WidgetSpreadsheet.HtmlFieldRenderer, editor: WidgetSpreadsheet.HtmlFieldEditor}},
      {data: "price", type: {renderer: WidgetSpreadsheet.ColoredNumberInputRenderer}},
      {data: "tax", type: {renderer: WidgetSpreadsheet.ColoredNumberInputRenderer}},
      {data: "total", type: {renderer: WidgetSpreadsheet.ColoredNumberInputRenderer}},
      {data: "currency_symbol", type: {renderer: WidgetSpreadsheet.EmptyLineTextRenderer, editor: function(){}}, source: G_currencies },
      {data: "currency", type: {renderer: WidgetSpreadsheet.EmptyLineTextRenderer, editor: function(){}}, source: G_currencies },
      {type: {renderer: WidgetSpreadsheet.MoveLineRenderer, editor: function(){}}},
      {type: {renderer: WidgetSpreadsheet.DropLineRenderer, editor: function(){}}}
    ]
  });

  //We don't want to capture the mouse wheel
  dom.find(".htCore").unbind('mousewheel');
}

WidgetSpreadsheet.prototype.set_price_ref = function(val){
  var dom = this.element.find(".dive_list_edit");
  var settings = dom.handsontable('getSettings');
  var new_settings = {columns: $.extend([], settings['columns'])};
  for (var i in new_settings.columns) {
    var col = new_settings.columns[i];
    if (col.data == 'price' || col.data == 'total') {
      if (val == col.data)
        col.type = {renderer: WidgetSpreadsheet.ColoredNumberInputRenderer};
      else
        col.type = {renderer: WidgetSpreadsheet.gen_CssTextRenderer({background: "#aaa", color: "#333"}), editor: function(){}};
    }
  }
  dom.handsontable('updateSettings', new_settings);
  dom.handsontable('render');
}

WidgetSpreadsheet.prototype.validateRow = function(data){
  var status = true;
  if (data.realm === null)
    data.realm = 'dive';
  if (data.id === null)
    delete data.id;
  if (data.shop_id === null)
    data.shop_id = G_shop_api.id;
  if (data.tax === null) {
    data.tax = "";
    status = false;
  }
  if (data.price === null || data.price === ''|| isNaN(Number(data.price))){
    data.price = "";
    status = false;
  }
  if (data.total === null || data.total === '' || isNaN(Number(data.total))){
    data.total = "";
    status = false;
  }
  if (G_dive_categories1.indexOf(data.cat1) < 0)
    status = false;
  return(status);
}

WidgetSpreadsheet.prototype.save = function() {
  var me=this;
  var full_data = this.element.findj;
  var data_to_send = [];
  var validity = true;

  $.each(full_data, function(i,e){
    e.order_num = i;
    if (e.hasChanged == null) return;
    data_to_send.push(e);
    validity = validity && me.validateRow(e);
  });

  console.log(data_to_send);

  var data_really_to_send = {
    id: G_shop_api.id,
    all_dive_goods: data_to_send
  };

  diveboard.mask_file(true);

  $.ajax({
    url: '/api/V2/shop',
    dataType: 'json',
    data: {
      arg: JSON.stringify(data_really_to_send),
      'authenticity_token': auth_token
    },
    type: "POST",
    success: function(data){
      if (data.success && (data.error == null||data.error.length==0)){
        window.location.replace(G_shop_api.permalink+"/edit/dive");
      } else if (data.success) {
        diveboard.alert(I18n.t(["js","shop_page_widgets","The data could not be completely updated"]), data, function(){
        diveboard.unmask_file();
        //window.location.replace('/'+G_shop_api['vanity_url']);
        });
      } else {
        //detail the alert
        diveboard.alert(I18n.t(["js","shop_page_widgets","A technical error occured."]), data, function(){
          diveboard.unmask_file();
        });
      }
    },
    error: function(data) {
      diveboard.alert(I18n.t(["js","shop_page_widgets","A technical error occured while saving the data. Please make sure your internet connection is up and try again."]), null, function() {
        diveboard.unmask_file();
      });
    }
  });
}

WidgetSpreadsheet.prototype.reset = function(){
  this.local_data = $.extend(true, [], G_dive_goods);
  this.has_changed = false;
  for (var i in this.local_data)
    this.local_data[i].hasChanged = false;
}


WidgetSpreadsheet.EmptyLineTextRenderer = function(instance, td, row, col, prop, value, cellProperties){
  if (instance.getData()[row].hasChanged === null)
    $(td).html('');
  else
    Handsontable.TextCell.renderer.apply(this, arguments);
}


WidgetSpreadsheet.gen_CssTextRenderer = function(css){
  return function(instance, td, row, col, prop, value, cellProperties){
    Handsontable.TextCell.renderer.apply(this, arguments);
    $(td).css(css);
  }
}

WidgetSpreadsheet.ColoredNumberInputRenderer = function(instance, td, row, col, prop, value, cellProperties){
  Handsontable.TextCell.renderer.apply(this, arguments);
  $(td).css({background: "", color: ""});
  //apply color except on extra line
  if ( instance.getData()[row].hasChanged === null || (value !== null && diveboard.isNumeric(value))) {
    $(td).removeClass('invalid_data');
  } else {
    $(td).addClass('invalid_data');
  }
}

WidgetSpreadsheet.ColoredAutocompleteCellRenderer = function(instance, td, row, col, prop, value, cellProperties){
  Handsontable.AutocompleteCell.renderer.apply(this, arguments);
  if (instance.getData()[row].hasChanged === null || (cellProperties.source.indexOf(value)>=0 )) {
    $(td).removeClass('invalid_data');
  } else {
    $(td).addClass('invalid_data');
  }
}

WidgetSpreadsheet.hasChangedRenderer = function(instance, td, row, col, prop, value, cellProperties){
  var check = '<input type="checkbox" disabled="disabled" ';
  if (value) check += ' checked=checked ';
  check += '/>';
  $(td).html(check);
};

WidgetSpreadsheet.MoveLineRenderer = function(instance, td, row, col, prop, value, cellProperties){
  //Check if it's an additional line
  if (instance.getData()[row].hasChanged === null) {
    $(td).html('');
    return;
  }

  var button_down = $("<button class='grey_button_small down_spreadsheet_line'>"+I18n.t(["js","shop_page_widgets","Down"])+"</button>");
  var button_up = $("<button class='grey_button_small up_spreadsheet_line'>"+I18n.t(["js","shop_page_widgets","Up"])+"</button>");
  $(td).css({'text-align': 'center'});
  $(td).html('');
  $(td).append(button_up);
  $(td).append("<br/>");
  $(td).append(button_down);
  button_up.bind('click', function(){
    var data = instance.getData();
    if (row == 0) return;
    if (data[row].hasChanged === null) return;

    var obj_tmp = data[row-1];
    data[row-1] = data[row];
    data[row] = obj_tmp;
    instance.selectCell(row-1, col);
    instance.render();
  });

  button_down.bind('click', function(){
    var data = instance.getData();
    if (data[row].hasChanged === null) return;
    if (data[row+1] === null) return;
    if (data[row+1].hasChanged === null) return;

    var obj_tmp = data[row+1];
    data[row+1] = data[row];
    data[row] = obj_tmp;
    instance.selectCell(row+1, col);
    instance.render();
  });
}


WidgetSpreadsheet.DropLineRenderer = function(instance, td, row, col, prop, value, cellProperties){
  if (instance.getData()[row].hasChanged === null) {
    $(td).html('');
    return;
  }
  var this_id = instance.getData()[row].id;

  var button = $("<button class='grey_button_small delete_spreadsheet_line'>"+I18n.t(["js","shop_page_widgets","Delete"])+"</button>")
  var loader = $("<img src='/img/transparent_loader_2.gif' style='display:none; width:20px; margin: 3px 0px 0px 0px;' class='spinner'/>");
  $(td).css({'text-align': 'center'});
  $(td).html('');
  $(td).append(button);
  $(td).append(loader);

  button.bind('click', function(){
    instance.deselectCell();
    instance.alter('remove_row', row);
    instance.render();
    /*
    $(td).find('.delete_spreadsheet_line').hide();
    $(td).find(".spinner").show();
    $.ajax({
      url: '/api/V2/good/'+this_id,
      dataType: 'json',
      data: {
        'authenticity_token': auth_token
      },
      type: "DELETE",
      success: function(data){
        if (data.success && (data.error == null||data.error.length==0)){
          instance.alter('remove_row', row);
          instance.updateSettings({});
          instance.render();
        } else if (data.success) {
          diveboard.alert("The line could not be correctly deleted.", data, function(){
            $(td).find('.delete_spreadsheet_line').show();
            $(td).find(".spinner").hide();
            //window.location.replace('/'+G_shop_api['vanity_url']);
          });
        } else {
          //detail the alert
          diveboard.alert("A technical error occured.", data, function(){
            $(td).find('.delete_spreadsheet_line').show();
            $(td).find(".spinner").hide();
          });
        }
      },
      error: function(data) {
        diveboard.alert("A technical error occured while deleting the data. Please make sure your internet connection is up and try again.", null, function() {
          $(td).find('.delete_spreadsheet_line').show();
          $(td).find(".spinner").hide();
        });
      }
    });
    */
  });
}


WidgetSpreadsheet.HtmlFieldRenderer = function(instance, td, row, col, prop, value, cellProperties){
  var a=$("<div></div>");
  a.html(value);
  var txt = a.text();
  if (txt.length == 0 && value && value.length > 10)
    txt = '....';
  else if (txt.length > 200)
    txt = txt.slice(0,200) + "...";
  $(td).text(txt);
}

WidgetSpreadsheet.HtmlFieldEditor = function(instance, td, row, col, prop, keyboardProxy, cellProperties){

  $(td).on('dblclick.editor', function(){WidgetSpreadsheet.HtmlFieldEditorWidget(instance, td, row, col, prop, keyboardProxy, cellProperties)});

  keyboardProxy.on("keydown.editor", function (event) {
    //if delete or backspace then empty cell
    if ([8, 46].indexOf(event.keyCode)>=0) {
      if (instance.getData()[row].description !== null)
        instance.getData()[row].hasChanged = true;
      instance.getData()[row].description = null;
      return;
    }

    //On enter or F2 or any printable key then open editor (key is lost though....)
    if ([13, 113].indexOf(event.keyCode)<0 && !Handsontable.helper.isPrintableChar(event.keyCode)) return;
    WidgetSpreadsheet.HtmlFieldEditorWidget(instance, td, row, col, prop, keyboardProxy, cellProperties);
  });

  return(function(){
    console.log('off');
    keyboardProxy.off("keydown.editor");
    $(td).off('dblclick.editor');
  });
}

WidgetSpreadsheet.HtmlFieldEditorWidget = function (instance, td, row, col, prop, keyboardProxy, cellProperties){
  instance.deselectCell();
  var dialog = $("<div><div class='elrte_editor'></div></div>");
  var editor = dialog.find('.elrte_editor');
  editor.html(instance.getData()[row].description);
  console.log(instance.getData()[row].description);
  console.log(editor.html());

  dialog.dialog({
    resizable: false,
    modal: true,
    width: 700,
    zIndex: 99999,
    close: function(){
      instance.render();
    },
    buttons:{
      ok: function(){
          instance.getData()[row].description = editor.elrte('val');
          instance.getData()[row].hasChanged = true;
          $( this ).dialog("close");
      },
      cancel: function(){
          $( this ).dialog("close");
      }
    }});

  //Gives focus to the dialog
  dialog.click();

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

  editor.elrte(opts);
  dialog.dialog("option", "position", "center");
}


//
//
// Control REALMACTIVATION
//
//

function WidgetRealmActivation(dom){
  //this part is run when new is called
  this.element = $(dom);
  this.initialized = false;
  this.hasChanged = false;
  this.realm = $(dom).attr('data-realm');
  if (!this.constructor.is_class_initialized && this.constructor.classInitialize)
    this.constructor.classInitialize();
}

WidgetRealmActivation.classInitialize = function(){
  this.is_class_initialized = true;
}

WidgetRealmActivation.prototype.is_initialized = function(){
  return this.initialized;
  //prevents dom from being multi-initialized
}

WidgetRealmActivation.prototype.init = function(){
  this.initialized = true;
  var me = this;
  this.element.find('.select_realm_activation').bind('change', function(){
    me.save();
  });
}

WidgetRealmActivation.prototype.has_changed = function(){
  //tells the global save wether there is anything to do here
  return false;
}

WidgetRealmActivation.prototype.save = function(){
  var me=this;
  me.element.find(".spin_ok_nok").html("<img src='/img/transparent_loader_2.gif' style='width: 20px; height: 20px; position: relative; top: 5px;'/>").show();

  var data = {id: G_shop_api['id']};
  data[me.realm] = me.element.find('.select_realm_activation').val();

  $.ajax({
    url: '/api/V2/shop',
    type: "POST",
    data: {
      'authenticity_token': auth_token,
      'arg': JSON.stringify(data)
    },
    success:function(data){
      if (data.success && (data.error == null||data.error.length==0)){
        me.element.find(".spin_ok_nok").html("<span class='symbol' style='color: #3A3'>.</span>").delay(1000).fadeOut(500);
      } else if (data.success) {
        me.element.find(".spin_ok_nok").html("<span class='symbol' style='color: #D33'>'</span>").delay(1000).fadeOut(500);
        console.log(data);
      } else {
        me.element.find(".spin_ok_nok").html("<span class='symbol' style='color: #D33'>'</span>").delay(1000).fadeOut(500);
        console.log(data);
      }
    },
    error: function(a){
      me.element.find(".spin_ok_nok").html("<span class='symbol' style='color: #D33'>'</span>").delay(1000).fadeOut(500);
      console.log(a);
    }
  });

  //does the save by himself
}




//
//
// Widget INITREALMDIVE
//
//

function WidgetInitRealmDive(dom){
  //this part is run when new is called
  this.element = $(dom);
  this.initialized = false;
  this.hasChanged = false;
  if (!this.constructor.is_class_initialized && this.constructor.classInitialize)
    this.constructor.classInitialize();
}

WidgetInitRealmDive.classInitialize = function(){
  this.is_class_initialized = true;
}

WidgetInitRealmDive.prototype.is_initialized = function(){
  return this.initialized;
  //prevents dom from being multi-initialized
}

WidgetInitRealmDive.prototype.init = function(){
  this.initialized = true;
  var me = this;
  this.element.find('.submit_init').bind('click', function(){
    me.save();
  });
}

WidgetInitRealmDive.prototype.has_changed = function(){
  //tells the global save wether there is anything to do here
  return false;
}

WidgetInitRealmDive.prototype.save = function(){
  var me=this;
  me.element.find(".spin_ok_nok").html("<img src='/img/transparent_loader_2.gif' style='width: 20px; height: 20px; position: relative; top: 5px;'/>").show();

  var data = {id: G_shop_api['id']};
  data.init_realm_dive = {};

  me.element.find("input[type='checkbox']").each(function(i,e){
    if ($(e).is(':checked'))
      data.init_realm_dive[$(e).attr('name')] = true;
  });

  if (me.element.find('.currency_select').length > 0)
    data.currency = me.element.find('.currency_select').val();

  diveboard.mask_file(true);

  $.ajax({
    url: '/api/V2/shop',
    type: "POST",
    data: {
      'authenticity_token': auth_token,
      'arg': JSON.stringify(data)
    },
    success:function(data){
      if (data.success && (data.error == null||data.error.length==0)){
        me.element.find(".spin_ok_nok").html("<span class='symbol' style='color: #3A3'>.</span>").delay(1000).fadeOut(500);
        window.location.replace(G_shop_api.permalink+"/edit/dive");
      } else if (data.success) {
        me.element.find(".spin_ok_nok").html("<span class='symbol' style='color: #D33'>'</span>").delay(1000).fadeOut(500);
        console.log(data);
        window.location.replace(G_shop_api.permalink+"/edit/dive");
      } else {
        me.element.find(".spin_ok_nok").html("<span class='symbol' style='color: #D33'>'</span>").delay(1000).fadeOut(500);
        console.log(data);
        window.location.replace(G_shop_api.permalink+"/edit/dive");
      }
    },
    error: function(a){
      me.element.find(".spin_ok_nok").html("<span class='symbol' style='color: #D33'>'</span>").delay(1000).fadeOut(500);
      console.log(a);
      window.location.replace(G_shop_api.permalink+"/edit/dive");
    }
  });

  //does the save by himself
}



//
//
// Widget ADVERTISEMENT EDITOR
//
//

function WidgetAdsEditor(dom){
  //this part is run when new is called
  this.element = $(dom);
  this.initialized = false;
  if (!this.constructor.is_class_initialized && this.constructor.classInitialize)
    this.constructor.classInitialize();
}

WidgetAdsEditor.classInitialize = function(){
  this.is_class_initialized = true;
  //this code is run at most once, whatever the number of this kind of widgets on the page
}


WidgetAdsEditor.prototype.is_initialized = function(){
  return this.initialized;
  //prevents dom from being multi-initialized
}


WidgetAdsEditor.prototype.init = function(){
  this.initialized = true;
  initialize_ad();
}

WidgetAdsEditor.prototype.has_changed = function(){
  //tells the global save wether there is anything to do here
  return false;
}

WidgetAdsEditor.prototype.save = function(){
  //does the save by himself
}






//
//
// Widget ADVERTISEMENT EDITOR
//
//

function WidgetReview(dom){
  //this part is run when new is called
  this.element = $(dom);
  this.initialized = false;
  if (!this.constructor.is_class_initialized && this.constructor.classInitialize)
    this.constructor.classInitialize();
}

WidgetReview.classInitialize = function(){
  this.is_class_initialized = true;
  //this code is run at most once, whatever the number of this kind of widgets on the page

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

  $(".leave_review_shop").live('click',function(e){
    if (e) e.preventDefault();
    open_new_review_form();
  });

  initialize_shop_claim();
}


WidgetReview.prototype.is_initialized = function(){
  return this.initialized;
  //prevents dom from being multi-initialized
}


WidgetReview.prototype.init = function(){
  this.initialized = true;

  //initialize standard display
  initialize_form_review({
    on_success: function(data){
      if (data.success && (data.error == null||data.error.length==0)){
        window.location.replace('/'+G_shop_api['vanity_url']);
      } else if (data.success) {
        diveboard.alert(I18n.t(["js","shop_page_widgets","The data could not be completely updated"]), data, function(){
          window.location.replace('/'+G_shop_api['vanity_url']);
        });

      } else {
        //detail the alert
        diveboard.alert(I18n.t(["js","shop_page_widgets","A technical error occured."]), data, function(){
          diveboard.unmask_file();
        });
      }
    }
  });

}

WidgetReview.prototype.has_changed = function(){
  //tells the global save wether there is anything to do here
  return false;
}

WidgetReview.prototype.save = function(){
  //does the save by himself
}






//
//
// Widget ADVERTISEMENT EDITOR
//
//

function WidgetListDives(dom){
  //this part is run when new is called
  this.element = $(dom);
  this.initialized = false;
  if (!this.constructor.is_class_initialized && this.constructor.classInitialize)
    this.constructor.classInitialize();
}

WidgetListDives.classInitialize = function(){
  this.is_class_initialized = true;
  //this code is run at most once, whatever the number of this kind of widgets on the page
}


WidgetListDives.prototype.is_initialized = function(){
  return this.initialized;
  //prevents dom from being multi-initialized
}


WidgetListDives.prototype.init = function(){
  this.initialized = true;
}

WidgetListDives.prototype.has_changed = function(){
  //tells the global save wether there is anything to do here
  return false;
}

WidgetListDives.prototype.save = function(){
  //does the save by himself
}


