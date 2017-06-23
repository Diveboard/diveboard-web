G_offset_arrow = 14;

$(document).ready(function(){

  //
  // Bindings
  //
  $(".shop_sidebar_menu a").click(change_realm);

  $(".arrow_left").css('top', $(".shop_sidebar_menu .selected").position().top + G_offset_arrow);

 $(".tab_link").live('click', function(e) {
    if (e) e.preventDefault();
    var link = $(this);
    var realm = link.closest('.realm');
    var tab_name = link.attr('id').replace(/_link$/,'');
    realm.find(".tab_link").removeClass('active');
    link.addClass('active');
    realm.find(".tab_panel").hide();
    realm.find("."+tab_name).show();
    $(".widget_holder:visible").each(function(i,e){
      widget_init($(e));
    });
  });

  share_initialize();
  initialize_follow_links();

  $(".save_link").click(function(e){
    e.preventDefault();
    save_all_widgets();
  });

  $('.add_widget').live('click', function(){
    $("#add_widget_dialog").dialog('close');
    widget_add($(this).attr('data-widget_type'), $(this).closest('#add_widget_dialog').data('target_page'));
  });

  $('.add_widget_ask').live('click', function(){
    widget_add_dialog($(this).closest('.realm'));
  });

  $(".make_realm_public").live('click', function(){
    var realm = $(this).closest('.realm');
    change_realm_privacy(realm, true);
  });

  $(".make_realm_private").live('click', function(){
    var realm = $(this).closest('.realm');
    change_realm_privacy(realm, false);
  });

  init_inquiry();
  init_buy();

  //
  // Widget initialisation
  //
  $(".widget_holder:visible").each(function(i,e){
    widget_init($(e));
  });

  $(".widget_controls .column_select").live('change', function(e){
    var dom = $(this);
    change_widget_column(dom.closest('.widget_holder'), dom.val());
  });

  $(".widget_controls .move_up").live('click', function(e){
    widget_move_up($(this).closest('.widget_holder'));
  });

  $(".widget_controls .move_down").live('click', function(e){
    widget_move_down($(this).closest('.widget_holder'));
  });

  $(".widget_controls .widget_delete").live('click', function(e){
    widget_delete($(this).closest('.widget_holder'));
  });

  //
  //Stay on scroll buttons
  //
  $(window).scroll(function(){
    var margin = 10;
    var header_height = $("#header_container").height();
    var header_bottom = $("#header_container").offset().top + header_height;
    $(".stay_on_scroll").each(function(i,e){
      var object = $(e);
      if (object.is(":visible")) {
        if (object.css('position') != 'fixed' && object.offset().top < header_bottom + margin){
            object.data('initial_parent', object.offsetParent());
            object.data('initial_position', object.position());
            object.css({'position': 'fixed', 'top': header_height+margin, 'left': object.offset().left});
        } else if (object.css('position') == 'fixed'){
          var parent_offset = object.data('initial_parent').offset();
          var calculated_position = parent_offset.top + object.data('initial_position').top;
          if (calculated_position > header_bottom + margin){
            object.css({'position': '', 'top': '', left: ''});
          }
        }
      }
    });
  });

  //Call load function for current_realm
  try{
    var current_realm = $(".shop_sidebar_menu a.selected").data('page');
    if (current_realm) {
      console.log(current_realm+"_load(true)");
      window[current_realm+"_load"](true);
    }
  }catch(e){}

  initialize_dropdowns();
});

function change_realm(e){
  e.preventDefault();
  $(".shop_sidebar_menu .selected").removeClass("selected");
  var target = $(e.target).closest("a");
  target.addClass("selected");
  var new_ticker_position = G_offset_arrow + target.position().top;
  $(".arrow_left").animate({top: new_ticker_position+"px"}, 500);
  $(".realm").hide();
  var destination_realm = target.data("page");
  $("."+destination_realm+"_page").show();
  $(".widget_holder:visible").each(function(i,e){
    widget_init($(e));
  });
  try{
    console.log(destination_realm+"_load(false)");
    window[destination_realm+"_load"](false);
  }catch(e){
    //no realm function maybe ?
  }
  try {
    var url = G_shop_api.permalink+"/";
    if (target.data('mode') == 'edit') url += "edit/";
    url += destination_realm;
    history.pushState("", "", url);
  } catch(e){}
}

//
// Widget manipulation functions
//

function widget_init(elt){
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

function save_all_widgets(){
  diveboard.mask_file(true);

  var data_changed=[];

  $(".realm").each(function(i,e){
    var realm = $(e);
    var realm_name = realm.attr('data-realm');

    realm.find('.widget_page').children().each(function(i,e){
      var col = $(e);
      var colnum = col.attr('data-colnum');
      var col_data=[];
      col.find('.widget_holder').each(function(i,e){
        var widget_data = {
          class_name: $(e).attr('data-widget_class'),
          id: $(e).attr('data-widget_id')
        };

        var widget = $(e).data('widget_object');
        if (widget && widget.data_for_save && widget.is_initialized() && (!widget.has_changed || widget.has_changed()))
          widget_data['data'] = widget.data_for_save();

        col_data.push(widget_data);
      });

      if (col_data.length > 0)
        data_changed.push({
          realm: realm_name,
          column: colnum,
          widgets: col_data
        });
    });
  });

  if (console && console.log)
    console.log(data_changed);

  $.ajax({
    url: '/api/widget_update',
    type: "POST",
    data: {
      'authenticity_token': auth_token,
      page_type: 'Shop',
      page_id: G_shop_api.id,
      set: G_shop_api.displayed_set,
      contents: JSON.stringify(data_changed)
    },
    success: function(data){
      if (data.success) {
        diveboard.unmask_file();
      } else {
        diveboard.alert(I18n.t(["js","shop_page","A technical error occured while saving the changes"]), data);
      }
    },
    error: function(data){
      diveboard.alert(I18n.t(["js","shop_page","A technical error occured while saving the changes"]), data);
    }
  })
}


function widget_delete(dom){
  var widget = dom.data('widget_object');
  if (widget.on_delete)
    widget.on_delete();
  dom.detach();
  validate_column_structure(dom.closest('.widget_page'));
}

function change_widget_column(dom, new_value){
  var father = dom.parent();
  var uncle = father.prev();
  var aunt = father.next();
  var widget = dom.data('widget_object');

  if (father.attr('data-colnum') == new_value) {
    return;
  } else if (uncle && aunt && uncle.attr('data-colnum') == new_value && aunt.attr('data-colnum') == new_value) {
      uncle.append(aunt.children());
      aunt.detach();
  } else if (uncle && uncle.attr('data-colnum') == new_value) {
    uncle.append(dom);
  } else if (aunt && aunt.attr('data-colnum') == new_value) {
    aunt.prepend(dom);
  } else {
    var step_father = $("<div class='widgets_col"+new_value+"' data-colnum='"+new_value+"'></div>");
    $(step_father).insertBefore(father);
    step_father.append(dom);
  }

  if (father.attr('data-colnum') == 0 && father.children().length == 0)
    father.detach();
  if (widget.refresh)
    widget.refresh();

  validate_column_structure(dom.closest('.widget_page'));
  $('html, body').animate({scrollTop: dom.offset().top + 'px'}, 'fast');
}

function widget_move_up(dom){
  var column = dom.parent();
  var colnum = column.attr('data-colnum');
  var widget = dom.data('widget_object');
  var prev = dom.prev();
  if (prev[0]) {
    dom.insertBefore(prev);
  } else {
    var prev_col = column.prev();
    while (prev_col[0] && prev_col.attr('data-colnum') != colnum)
      prev_col = prev_col.prev();
    if (prev_col[0]) {
      prev_col.append(dom);
    } else if (colnum != 2) {
      var new_column = $("<div class='widgets_col"+colnum+"' data-colnum='"+colnum+"'></div>");
      column.parent().prepend(new_column);
      new_column.append(dom);
    } else if (colnum == 2) {
      var new_column1 = $("<div class='widgets_col"+1+"' data-colnum='"+1+"'>&nbsp;</div>");
      var new_column2 = $("<div class='widgets_col"+colnum+"' data-colnum='"+colnum+"'></div>");
      column.parent().prepend(new_column1);
      column.parent().prepend(new_column2);
      new_column2.append(dom);
    }

  }

  if (column.children().length == 0)
    column.detach();
  if (widget.refresh)
    widget.refresh();
  validate_column_structure(dom.closest('.widget_page'));
  $('html, body').animate({scrollTop: dom.offset().top + 'px'}, 'fast');
}

function widget_move_down(dom){
  var column = dom.parent();
  var colnum = column.attr('data-colnum');
  var widget = dom.data('widget_object');
  var next_dom = dom.next();
  if (next_dom[0]) {
    dom.insertAfter(next_dom);
  } else {
    var next_col = column.next();
    while (next_col[0] && next_col.attr('data-colnum') != colnum)
      next_col = next_col.next();
    if (next_col[0]) {
      next_col.prepend(dom);
    } else if (colnum != 2) {
      var new_column = $("<div class='widgets_col"+colnum+"' data-colnum='"+colnum+"'></div>");
      column.parent().append(new_column);
      new_column.append(dom);
    } else if (colnum == 2) {
      var new_column1 = $("<div class='widgets_col"+1+"' data-colnum='"+1+"'>&nbsp;</div>");
      var new_column2 = $("<div class='widgets_col"+colnum+"' data-colnum='"+colnum+"'></div>");
      column.parent().append(new_column1);
      column.parent().append(new_column2);
      new_column2.append(dom);
    }

  }

  if (column.children().length == 0)
    column.detach();
  if (widget.refresh)
    widget.refresh();
  validate_column_structure(dom.closest('.widget_page'));
  $('html, body').animate({scrollTop: dom.offset().top + 'px'}, 'fast');
}

function validate_column_structure(widget_page){
  var previous_element = null
  var previous_column = null;
  var current_element = widget_page.children().first();
  var current_column = current_element.attr('data-colnum');

  while(current_element[0]){
    //merge two columns that have the same colnum
    if (previous_column == current_column) {
      var movable = current_element.children();
      previous_element.append(movable);
      movable.each(function(i,e){
        var widget = $(e).data('widget_object');
        if (widget.refresh)
          widget.refresh();
      });
      current_element.detach();
      current_column = previous_column;
      current_element = previous_element;
    }

    //Column 1 cannot be directly after 2
    else if (current_column == 1 && previous_column == 2) {
      var movable = current_element.children();
      previous_element.prev().append(movable);
      movable.each(function(i,e){
        var widget = $(e).data('widget_object');
        if (widget.refresh)
          widget.refresh();
      });
      current_element.detach();
      current_column = previous_column;
      current_element = previous_element;
    }

    //Missing col 1
    else if (current_column == 2 && (previous_column == null || previous_column != 1)) {
      var new_column1 = $("<div class='widgets_col"+1+"' data-colnum='"+1+"'>&nbsp;</div>");
      new_column1.insertBefore(current_element);
      previous_element = new_column1;
      previous_column = 1;
    }


    previous_column = current_column;
    previous_element = current_element;
    current_element = current_element.next();
    current_column = current_element.attr('data-colnum');
  }

  widget_page.find('.widgets_col1').each(function(i,e){
    var current_element = $(e);
    //Removing &nbsp; needed in empty columns
    if (current_element.children().length > 0)
      current_element.contents().filter(function() {return this.nodeType === 3; /*Node.TEXT_NODE*/ }).detach();
  });
}

function widget_add_dialog(realm){
  $("#add_widget_dialog").data('target_page', realm.find('.widget_page'));
  $("#add_widget_dialog").dialog({
    resizable: false,
    modal: true,
    zIndex: 99999,
    width: 700,
    buttons: {
      "Cancel": function() {
        $( this ).dialog( "close" );
      }
    }
  });
}

function widget_add(widget_type, widget_page){
  var dom = $("#widget_model_"+widget_type).clone();
  var new_column = $("<div class='widgets_col0' data-colnum='0'>&nbsp;</div>");
  dom.attr({'class': 'widget_holder widget_'+widget_type, 'id': null });
  new_column.append(dom);
  widget_page.append(new_column);
  widget_init(dom);

  validate_column_structure(widget_page);
  $('html, body').animate({scrollTop: dom.offset().top + 'px'}, 'fast');
}

//
//
// General functions
//
//
function change_realm_privacy(realm, public_flag) {
    var realm_name = realm.attr('data-realm');
    var data = {id: G_shop_api['id']};
    data["realm_"+realm_name] = public_flag;
    diveboard.mask_file(true);

    $.ajax({
        url: '/api/V2/shop',
        dataType: 'json',
        data: {
          arg: JSON.stringify(data),
          'authenticity_token': auth_token
        },
        type: "POST",
        success: function(data){
          if (data.success && (data.error == null||data.error.length==0)){
            diveboard.unmask_file();
            if (public_flag) {
              realm.find('.make_realm_private').show();
              realm.find('.make_realm_public').hide();
            } else {
              realm.find('.make_realm_private').hide();
              realm.find('.make_realm_public').show();
            }
          } else if (data.success) {
            diveboard.alert(I18n.t(["js","shop_page","The change could not be completed. Please save your changes, reload the page and retry."]), data, function(){
            diveboard.unmask_file();
            //window.location.replace('/'+G_shop_api['vanity_url']);
            });
          } else {
            //detail the alert
            diveboard.alert(I18n.t(["js","shop_page","A technical error occured."]), data, function(){
              diveboard.unmask_file();
            });
          }
        },
        error: function(data) {
          diveboard.alert(I18n.t(["js","shop_page","A technical error occured while saving the dive. Please make sure your internet connection is up and try again."]), null, function() {
            diveboard.unmask_file();
          });
        }
      });
}


//
// General inquiry functions
//
function init_inquiry(){
  $(".inquiry_button").live('click', function(){
    $("#dialog_general_inquiry").dialog({
      resizable: false,
      modal: true,
      width: '700px',
      zIndex: 99999,
      buttons: {}
    });
    ga('send', 'event', 'shop', 'contact_us');
  });

  $("#dialog_general_inquiry .submit_inquiry").live("click", function(){
    var dlg = $(this).closest("#dialog_general_inquiry");

    var message = dlg.find('.message_text').val();
    if (!message || message.length<10) {
      diveboard.notify(I18n.t(["js","shop_page","Message validation"]), I18n.t(["js","shop_page","Your message must be at least 10 characters long."]));
      return;
    }

    diveboard.mask_file(true);
    dlg.dialog('close');

    var data_to_send = {
      topic: dlg.find('.topic_text').val(),
      message: dlg.find('.message_text').val(),
      from: {id: G_user_api.id},
      to: {id: dlg.data('to_id')}
    };

    if (dlg.data('in_reply_to_id') && dlg.data('in_reply_to_type')) {
      data_to_send.in_reply_to_type = dlg.data('in_reply_to_type');
      data_to_send.in_reply_to_id = dlg.data('in_reply_to_id');
    }

    diveboard.api_call("message", data_to_send, function(){
      dlg.find('.message_text').val("");
      dlg.find('.topic_text').val(null);
      diveboard.unmask_file();
      var message = dlg.find(".ok_text").clone().removeClass('hidden').appendTo("<div/>").parent().html(); //getting the elements HTML
      diveboard.notify(dlg.attr('title'), message);
    }, function(){
      diveboard.unmask_file();
    }, 'public');

  });

  $("#dialog_general_inquiry .cancel_inquiry").live("click", function(){
    var dlg = $(this).closest("#dialog_general_inquiry");
    dlg.find('.message_text').val("");
    dlg.find('.topic_text').val(null);
    $(this).closest("#dialog_general_inquiry").dialog('close');
  });
}

//General buy functions
function init_buy(){

}



function dive_load(page_loading){
  $(".submit_paypal_id_button").live('click', function(ev){
    ev.preventDefault();
    var form = $(this).closest('form');
    var paypal_id = form.find("input[name=paypal_id]").val();
    paypal_id = paypal_id.replace(/ /g, '');

    if (paypal_id == '') {
      diveboard.notify(I18n.t(["js","shop_page","Paypal ID"]), I18n.t(["js","shop_page","Please fill in the Paypal ID field."]));
    } else if (!paypal_id.match(/.+@.+\..+/)) {
      diveboard.notify(I18n.t(["js","shop_page","Paypal ID"]), I18n.t(["js","shop_page","Your paypal ID does not look valid. Please check again."]))
    } else {
      diveboard.mask_file(true);
      form.submit();
    }
  });

  $(".currency_select_block .send").live('click', function(){
    var form = $(this).closest('.currency_select_block');
    var currency = form.find(".currency_select").val();
    diveboard.mask_file(true);
    diveboard.api_call("shop", {
        'id': G_shop_api.id,
        'currency': currency
      }, function(){
        window.location.href = window.location.href;
        window.location.reload(true);
      }, function(){
        diveboard.unmask_file();
      }, 'public');
  });


  $(".paypal_unlink_button").live('click', function(){
    diveboard.propose(I18n.t(["js","shop_page","Unlink Paypal account"]), I18n.t(["js","shop_page","Unlinking your paypal account will disable all Paypal sells. Are you sure ?"]), {"Cancel": function(){}, "OK": function(){
      diveboard.mask_file(true);
      diveboard.api_call("shop", {
          'id': G_shop_api.id,
          'paypal_id': null
        }, function(){
          window.location.href = window.location.href;
          window.location.reload(true);
        }, function(){
          diveboard.unmask_file();
        }, 'public');
    }});
  });
}


function care_load(page_loading){
  if (!care_load.initialized) {
    care_load.initialized = true
    init_buy_manage();
  }
  if (!page_loading && $(".realm.care_page .main_page_marker").length == 0) {
    diveboard.mask_file(true);
    $(".realm.care_page .tab_panel").load(G_shop_api.permalink+"/partial/care", function(){
      try {
        history.pushState("", "", G_shop_api.permalink+"/care");
      } catch(e){}
      init_content4_buy_manage();
      diveboard.unmask_file();
    });
  }
}


function init_buy_manage(){
  try {
    init_content4_buy_manage();
  }catch(e){}

  $(".basket_confirmation_action").live('change', function(){
    var action = $(".basket_confirmation_action").val();
    var form = $(this).closest('.basket_confirmation_form');
    form.find('.basket_confirmation_part').hide();
    form.find('.basket_confirmation_'+action).show();
  });

  $(".basket_confirmation_confirm .send").live('click', function(){
    var form = $(this).closest('.basket_confirmation_confirm');
    var url = "/api/basket/manage/confirm";
    var basket_id = form.data('basket_id');
    if (form.find('.also_deliver:checked').val())
      url = "/api/basket/manage/deliver";

    diveboard.mask_file(true);

    $.ajax({
      url: url,
      type: "POST",
      data: {
        basket_id: basket_id,
        note: form.find('.note_text').val(),
        'authenticity_token': auth_token
      },
      success: function(data){
        Header.update_ajax();
        if (data.success && data.error) {
          diveboard.alert(I18n.t(["js","shop_page","A technical error occured."]), data, function(){
            window.location = window.location.href;
          });
        } else if (data.success) {
          form.closest(".tab_panel").load(G_shop_api.permalink+"/partial/care/basket/"+basket_id, function(){
            try {
              history.pushState("", "", G_shop_api.permalink+"/care/basket/"+basket_id);
            } catch(e){}
            diveboard.unmask_file();
          });
        } else {
          //detail the alert
          diveboard.alert(I18n.t(["js","shop_page","A technical error occured."]), data, function(){
            window.location = window.location.href;
          });
        }
      },
      error: function(){
        diveboard.alert(I18n.t(["js","shop_page","A technical error occured."]), data, function(){
          diveboard.unmask_file();
        });
      }
    });
  });

  $(".basket_confirmation_deliver .send").live('click', function(){
    var form = $(this).closest('.basket_confirmation_deliver');
    var url = "/api/basket/manage/deliver";
    var basket_id = form.data('basket_id');

    diveboard.mask_file(true);
    $.ajax({
      url: url,
      type: "POST",
      data: {
        basket_id: basket_id,
        note: form.find('.note_text').val(),
        'authenticity_token': auth_token
      },
      success: function(data){
        Header.update_ajax();
        if (data.success && data.error) {
          diveboard.alert(I18n.t(["js","shop_page","A technical error occured."]), data, function(){
            window.location = window.location.href;
          });
        } else if (data.success) {
          form.closest(".tab_panel").load(G_shop_api.permalink+"/partial/care/basket/"+basket_id, function(){
            try {
              history.pushState("", "", G_shop_api.permalink+"/care/basket/"+basket_id);
            } catch(e){}
            diveboard.unmask_file();
          });
        } else {
          //detail the alert
          diveboard.alert(I18n.t(["js","shop_page","A technical error occured."]), data, function(){
            window.location = window.location.href;
          });
        }
      },
      error: function(){
        diveboard.alert(I18n.t(["js","shop_page","A technical error occured."]), data, function(){
          diveboard.unmask_file();
        });
      }
    });
  });

  $(".basket_confirmation_ask_detail .send").live('click', function(){
    var form = $(this).closest('.basket_confirmation_ask_detail');
    var url = "/api/basket/manage/ask_detail";
    var basket_id = form.data('basket_id');

    var message = form.find('.note_text').val();
    if (!message || message.length<10) {
      diveboard.notify(I18n.t(["js","shop_page","Message validation"]), I18n.t(["js","shop_page","Your message must be at least 10 characters long."]));
      return;
    }

    diveboard.mask_file(true);

    $.ajax({
      url: url,
      type: "POST",
      data: {
        basket_id: basket_id,
        message: message,
        'authenticity_token': auth_token
      },
      success: function(data){
        Header.update_ajax();
        if (data.success && data.error) {
          Header.update_ajax();
          diveboard.alert(I18n.t(["js","shop_page","A technical error occured."]), data, function(){
            window.location = window.location.href;
          });
        } else if (data.success) {
          form.closest(".tab_panel").load(G_shop_api.permalink+"/partial/care/basket/"+basket_id, function(){
            try {
              history.pushState("", "", G_shop_api.permalink+"/care/basket/"+basket_id);
            } catch(e){}
            diveboard.unmask_file();
          });
        } else {
          //detail the alert
          diveboard.alert(I18n.t(["js","shop_page","A technical error occured."]), data, function(){
            window.location = window.location.href;
          });
        }
      },
      error: function(){
        diveboard.alert(I18n.t(["js","shop_page","A technical error occured."]), data, function(){
          diveboard.unmask_file();
        });
      }
    });
  });


  $(".basket_confirmation_reject .send").live('click', function(){
    var form = $(this).closest('.basket_confirmation_reject');
    var url = "/api/basket/manage/reject";
    var basket_id = form.data('basket_id');

    var message = form.find('.note_text').val();
    if (!message || message.length<10) {
      diveboard.notify(I18n.t(["js","shop_page","Message validation"]), I18n.t(["js","shop_page","Your message must be at least 10 characters long."]));
      return;
    }

    diveboard.mask_file(true);
    $.ajax({
      url: url,
      type: "POST",
      data: {
        basket_id: form.data('basket_id'),
        message: message,
        'authenticity_token': auth_token
      },
      success: function(data){
        Header.update_ajax();
        if (data.success && data.error) {
          diveboard.alert(I18n.t(["js","shop_page","A technical error occured."]), data, function(){
            window.location = window.location.href;
          });
        } else if (data.success) {
          form.closest(".tab_panel").load(G_shop_api.permalink+"/partial/care/basket/"+basket_id, function(){
            try {
              history.pushState("", "", G_shop_api.permalink+"/care/basket/"+basket_id);
            } catch(e){}
            diveboard.unmask_file();
          });
        } else {
          //detail the alert
          diveboard.alert(I18n.t(["js","shop_page","A technical error occured."]), data, function(){
            window.location = window.location.href;
          });
        }
      },
      error: function(){
        diveboard.alert(I18n.t(["js","shop_page","A technical error occured."]), data, function(){
          diveboard.unmask_file();
        });
      }
    });
  });


  $(".basket_shop_table .basket_line").live('click', function(){
    diveboard.mask_file(true);
    var basket_id = $(this).data('basket_id');
    $(this).closest(".tab_panel").load(G_shop_api.permalink+"/partial/care/basket/"+basket_id, function(){
      try {
        history.pushState("", "", G_shop_api.permalink+"/care/basket/"+basket_id);
      } catch(e){}
      diveboard.unmask_file();
    });
  });

  $(".fake_link").live('click', function(e){
    e.preventDefault();
  });

  $(".back_to_orders_list").live('click', function(e){
    e.preventDefault();
    diveboard.mask_file(true);
    $(this).closest(".tab_panel").load(G_shop_api.permalink+"/partial/care", function(){
      try {
        history.pushState("", "", G_shop_api.permalink+"/care");
      } catch(e){}
      init_content4_buy_manage();
      diveboard.unmask_file();
    });
  });


  $(".shop_message_to_customer .submit_group_inquiry").live("click", function(){
    var dlg = $(this).closest(".shop_message_to_customer");

    var title = dlg.find(".topic_text").val();
    if (!title || title.length<5) {
      diveboard.notify(I18n.t(["js","shop_page","Message validation"]), I18n.t(["js","shop_page","Your topic must be at least 5 characters long."]));
      return;
    }

    var message = dlg.find('.message_text').val();
    if (!message || message.length<10) {
      diveboard.notify(I18n.t(["js","shop_page","Message validation"]), I18n.t(["js","shop_page","Your message must be at least 10 characters long."]));
      return;
    }

    var reload_url = $(this).data('reload_url');
    diveboard.mask_file(true);

    var data_to_send = {
      topic: title,
      message: message,
      from: {id: G_user_api.id},
      from_group: {id: $(this).data('group_id')},
      to: {id: $(this).data('to_id')},
    };

    if ($(this).data('in_reply_to_id') && $(this).data('in_reply_to_type')) {
      data_to_send.in_reply_to_type = $(this).data('in_reply_to_type');
      data_to_send.in_reply_to_id = $(this).data('in_reply_to_id');
    }

    diveboard.api_call("message", data_to_send, function(){
      if (reload_url && dlg.closest(".tab_panel")) {
        dlg.closest(".tab_panel").load(reload_url, function(){
          init_content4_buy_manage();
          diveboard.unmask_file();
        });
      } else {
        window.location.href = window.location.href;
        window.location.reload(true);
      }
    }, function(){
      diveboard.unmask_file();
    }, 'public');

  });

  $(".mark_as_read_group_inquiry").live("click", function(){
    diveboard.mask_file(true);
    var dlg = $(this);
    var reload_url = $(this).data('reload_url');
    var data_to_send = {
      id: dlg.data('message_id'),
      status: 'read'
    };
    diveboard.api_call("message", data_to_send, function(){
      dlg.closest(".tab_panel").load(reload_url, function(){
        init_content4_buy_manage();
        diveboard.unmask_file();
      });
      Header.update_ajax();
    }, function(){
      diveboard.unmask_file();
    }, 'public');
  });

  $(".message_shop_table .message_line").live('click', function(){
    diveboard.mask_file(true);
    var message_id = $(this).data('message_id');
    $(this).closest(".tab_panel").load(G_shop_api.permalink+"/partial/care/message/"+message_id, function(){
      try {
        history.pushState("", "", G_shop_api.permalink+"/care/message/"+message_id);
        var pos = document.getElementById(message_id).offsetTop+100;
        $('html,body').animate({scrollTop: pos}, 'fast');
      } catch(e){}
      diveboard.unmask_file();
    });
  });

  $(".customer_shop_table .customer_line").live('click', function(){
    diveboard.mask_file(true);
    var user_id = $(this).data('user_id');
    $(this).closest(".tab_panel").load(G_shop_api.permalink+"/partial/care/customer/"+user_id, function(){
      try {
        history.pushState("", "", G_shop_api.permalink+"/care/customer/"+user_id);
      } catch(e){}
      diveboard.unmask_file();
    });
  });



  $(".message_shop_table_filter").live('change', function(){
    var json_filter = JSON.stringify($(this).val());
    var start_id = 0;

    $(".message_shop_table .message_line").detach();
    $(".message_shop_table").hide();
    $(".message_shop_table_void").hide();
    $(".message_shop_table_next").hide();
    $(".message_shop_table_previous").hide();
    $(".message_shop_table_loading").show();

    $.ajax({
      url: '/api/V2/search/message',
      type: 'POST',
      data: {
        start_id: start_id,
        limit: 20,
        arg: json_filter,
        flavour: 'private,detailed',
        'authenticity_token': auth_token
      },
      success: function(data){
        if (data.success){
          G_messages_current_filter = json_filter;
          G_messages_previous=[start_id];
          G_messages = data;
          init_content4_buy_manage();
        }
      }
    });
  });


  $(".message_shop_table_next").live('click', function(){
    var json_filter = JSON.stringify($(".message_shop_table_filter").val());
    var start_id = G_messages.next_start_id;

    if (!start_id) return;

    $(".message_shop_table .message_line").detach();
    $(".message_shop_table_next").hide();
    $(".message_shop_table_previous").hide();
    $(".message_shop_table_loading").show();

    $.ajax({
      url: '/api/V2/search/message',
      type: 'POST',
      data: {
        start_id: start_id,
        limit: 20,
        arg: json_filter,
        flavour: 'private,detailed',
        'authenticity_token': auth_token
      },
      success: function(data){
        if (data.success){
          G_messages_previous.push(start_id);
          G_messages = data;
          init_content4_buy_manage();
        }
      }
    });
  });

  $(".message_shop_table_previous").live('click', function(){
    if (G_messages_previous.length <= 1) return;
    var json_filter = JSON.stringify($(".message_shop_table_filter").val());
    var start_id = G_messages_previous[G_messages_previous.length-2];

    $(".message_shop_table .message_line").detach();
    $(".message_shop_table_next").hide();
    $(".message_shop_table_previous").hide();
    $(".message_shop_table_loading").show();

    $.ajax({
      url: '/api/V2/search/message',
      type: 'POST',
      data: {
        start_id: start_id,
        limit: 20,
        arg: json_filter,
        flavour: 'private,detailed',
        'authenticity_token': auth_token
      },
      success: function(data){
        if (data.success){
          G_messages_previous.pop();
          G_messages = data;
          init_content4_buy_manage();
        }
      }
    });
  });


  $(".basket_shop_table_filter").live('change', function(){
    var json_filter = JSON.stringify($(this).val());
    var start_id = 0;

    $(".basket_shop_table .basket_line").detach();
    $(".basket_shop_table").hide();
    $(".basket_shop_table_void").hide();
    $(".basket_shop_table_next").hide();
    $(".basket_shop_table_previous").hide();
    $(".basket_shop_table_loading").show();

    $.ajax({
      url: '/api/V2/search/basket',
      type: 'POST',
      data: {
        start_id: start_id,
        limit: 20,
        arg: json_filter,
        flavour: 'private,detailed,items',
        'authenticity_token': auth_token
      },
      success: function(data){
        if (data.success){
          G_baskets_current_filter = json_filter;
          G_baskets_previous=[start_id];
          G_baskets = data;
          init_content4_buy_manage();
        }
      }
    });
  });

  $(".basket_shop_table_next").live('click', function(){
    var json_filter = JSON.stringify($(".basket_shop_table_filter").val());
    var start_id = G_baskets.next_start_id;

    if (!start_id) return;

    $(".basket_shop_table .basket_line").detach();
    $(".basket_shop_table_next").hide();
    $(".basket_shop_table_previous").hide();
    $(".basket_shop_table_loading").show();

    $.ajax({
      url: '/api/V2/search/basket',
      type: 'POST',
      data: {
        start_id: start_id,
        limit: 20,
        arg: json_filter,
        flavour: 'private,detailed,items',
        'authenticity_token': auth_token
      },
      success: function(data){
        if (data.success){
          G_baskets_previous.push(start_id);
          G_baskets = data;
          init_content4_buy_manage();
        }
      }
    });
  });

  $(".basket_shop_table_previous").live('click', function(){
    if (G_baskets_previous.length <= 1) return;
    var json_filter = JSON.stringify($(".basket_shop_table_filter").val());
    var start_id = G_baskets_previous[G_baskets_previous.length-2];

    $(".basket_shop_table .basket_line").detach();
    $(".basket_shop_table_next").hide();
    $(".basket_shop_table_previous").hide();
    $(".basket_shop_table_loading").show();

    $.ajax({
      url: '/api/V2/search/basket',
      type: 'POST',
      data: {
        start_id: start_id,
        limit: 20,
        arg: json_filter,
        flavour: 'private,detailed,items',
        'authenticity_token': auth_token
      },
      success: function(data){
        if (data.success){
          G_baskets_previous.pop();
          G_baskets = data;
          init_content4_buy_manage();
        }
      }
    });
  });



  $(".customer_shop_table_next").live('click', function(){
    var json_filter = '{"shop_id":'+G_shop_api.id+'}';
    var start_id = G_customers.next_start_id;

    if (!start_id) return;

    $(".customer_shop_table .customer_line").detach();
    $(".customer_shop_table_next").hide();
    $(".customer_shop_table_previous").hide();
    $(".customer_shop_table_loading").show();

    $.ajax({
      url: '/api/V2/search/shop_customer',
      type: 'POST',
      data: {
        start_id: start_id,
        limit: 20,
        flavour: 'public,for_shop',
        arg: json_filter,
        'authenticity_token': auth_token
      },
      success: function(data){
        if (data.success){
          G_customers_previous.push(start_id);
          G_customers = data;
          init_content4_buy_manage();
        }
      }
    });
  });

  $(".customer_shop_table_previous").live('click', function(){
    if (G_customers_previous.length <= 1) return;
    var json_filter = '{"shop_id":'+G_shop_api.id+'}';
    var start_id = G_customers_previous[G_customers_previous.length-2];

    $(".customer_shop_table .customer_line").detach();
    $(".customer_shop_table_next").hide();
    $(".customer_shop_table_previous").hide();
    $(".customer_shop_table_loading").show();

    $.ajax({
      url: '/api/V2/search/shop_customer',
      type: 'POST',
      data: {
        start_id: start_id,
        limit: 20,
        flavour: 'public,for_shop',
        arg: json_filter,
        'authenticity_token': auth_token
      },
      success: function(data){
        if (data.success){
          G_customers_previous.pop();
          G_customers = data;
          init_content4_buy_manage();
        }
      }
    });
  });

  $(".shop_customer_history_filter").live('change', function(){
    diveboard.mask_file(true);
    window.location = "?filter_history="+$(this).val();
  });

  $(".message_history_controls .reply_to").live('click', function(ev){
    ev.preventDefault();
    var button = $(this);
    var ref_id = $(this).data('reply_to_id');
    var ref_type = $(this).data('reply_to_type');
    var controls = $(this).closest('.message_history_controls');
    var top_container = controls.parent();

    var send_button = top_container.find('.reply_message .submit_group_inquiry');
    send_button.data('in_reply_to_type', ref_type);
    send_button.data('in_reply_to_id', ref_id);

    top_container.find('.reply_message').show('fold');
    controls.hide();
  });

  $(".message_history .reply_message .cancel_group_inquiry").live('click', function(){
    $(this).closest('.reply_message').hide();
    $(this).closest('.message_history').parent().find('.message_history_controls').show();
  });

  $(".history_item .mark_as_read").live('click', function(){
    var msgid = $(this).data('msgid');
    var msg_container = $(this).closest('.history_item');
    msg_container.addClass('status_change');
    diveboard.api_call("message", {
        'id': msgid,
        'status': 'read'
      }, function(data){
        if (data && data.result && data.result.status == 'read') {
          msg_container.addClass('read');
          msg_container.removeClass('unread');
        }
        msg_container.removeClass('status_change');
        Header.update_ajax();
      }, function(){
        msg_container.removeClass('status_change');
      }, 'public'
    );
  });

  $(".history_item .mark_as_unread").live('click', function(){
    var msgid = $(this).data('msgid');
    var msg_container = $(this).closest('.history_item');
    msg_container.addClass('status_change');
    diveboard.api_call("message", {
        'id': msgid,
        'status': 'new'
      }, function(data){
        if (data && data.result && data.result.status == 'new') {
          msg_container.addClass('unread');
          msg_container.removeClass('read');
        }
        msg_container.removeClass('status_change');
        Header.update_ajax();
      }, function(){
        msg_container.removeClass('status_change');
      }, 'public'
    );
  });

  $(".message_history_controls .mark_all_read").live('click', function(){
    var data_to_send = [];
    var list_elements = $(".message_received.unread").not(".status_change");
    list_elements.each(function(i,e){
      var msg_id = $(e).find(".mark_as_read").data('msgid');
      if (msg_id) data_to_send.push({'id':msg_id,'status':'read'});
    });

    if (data_to_send.length == 0) return;

    list_elements.addClass('status_change');

    diveboard.api_call("message", data_to_send, function(data){
        console.log(data);
        if (data && data.result) {
          for (var i in data.result){
            var message = data.result[i];
            var msg_box = $(".message_received .mark_as_read[data-msgid='"+message.id+"']").closest('.message_received');
            msg_box.removeClass('read').removeClass('unread').removeClass('status_change');
            if (message.status == 'new')
              msg_box.addClass('unread');
            else
              msg_box.addClass('read');
          }
        }
        list_elements.removeClass('status_change');
        Header.update_ajax();
      }, function(){
        list_elements.removeClass('status_change');
      }, 'public'
    );
  });


  //////
  //  JS functions for the dive signature
  //////

  $("#sign_select_all").live('click', function(e){
    e.preventDefault();
    $(".signature_table input").attr("checked", true);
  });

 $("#sign_unselect_all").live('click', function(e){
    e.preventDefault();
    $(".signature_table input").removeAttr("checked");
  });

 $(".sign_one_dive").live('click', function(e){
     var sign_target = $(e.target).closest("li");
     var id_array = [sign_target.data("signature-id")];
     var action = null;
     if ($(e.target).hasClass("validate_sign_dive"))
      action = 1;
     else if ($(e.target).hasClass("reject_sign_dive"))
      action = 0;
     sign_target.find(".sign_actions").hide();
     sign_target.find(".sign_spinner").css("display", "inline-block");
     sign_target.find("input").attr("DISABLED", true).removeAttr("CHECKED");
     sign_dives(
      id_array,
      action,
      function(){
        sign_target.detach();
      },
      function(){
        sign_target.find(".sign_spinner").hide();
        sign_target.find(".sign_actions").css("display", "inline-block");
      }
    );
 });

  $(".sign_bulk_dive").live('click', function(e){
     var obj_array = $(".signature_table input:checked").not( "[disabled]" );
     var id_array = $.map(obj_array, function(e,i){return $(e).closest("li").data("signature-id");});
     var action = null;

     if(id_array.length == 0){
      diveboard.notify(I18n.t(["js","shop_page","Could not complete action"]), I18n.t(["js","shop_page","You need to select at least one dive"]));
      return;
     }

     if ($(e.target).hasClass("validate_sign_dive"))
      action = 1;
     else if ($(e.target).hasClass("reject_sign_dive"))
      action = 0;
    $.each(obj_array, function(idx, el){
      var sign_target = $(el).closest("li");
      sign_target.find(".sign_actions").hide();
      sign_target.find(".sign_spinner").css("display", "inline-block");
      sign_target.find("input").attr("DISABLED", true).removeAttr("CHECKED");
    });
    sign_dives(
      id_array,
      action,
      function(){
        $.each(obj_array, function(idx, el){$(el).closest("li").detach();});
      },
      function(){
        $.each(obj_array, function(idx, el){
          var sign_target = $(el).closest("li");
          sign_target.find(".sign_spinner").hide();
          sign_target.find(".sign_actions").css("display", "inline-block");
        });

      }
    );
 });


}

function sign_dives(id_array, action_type ,callback_success, callback_fail){
  //if action_type == 1 -> sign
  //if action_type == 0 -> reject
  // will call /api/care/sign_dives
  $.ajax({
      url: '/api/care/sign_dives',
      type: 'POST',
      data: {
        sign_ids: id_array,
        sign_action: action_type,
        shop_id: G_shop_api.id,
        'authenticity_token': auth_token
      },
      success: function(data){
        if (data.success){
          if (callback_success)
            callback_success();
            if ($(".signature_table li").length == 0){
              $(".sign-tasks").hide();
              $(".sign-tasks-empty").show();
            }
        }else{
          diveboard.notify(I18n.t(["js","shop_page","Error signing dive"]) ,data.error[0], callback_fail);
        }
      },
      error: function(data){
        diveboard.alert(I18n.t(["js","shop_page","Server did not answer"]), data, callback_fail);
      }
    });
}



function init_content4_buy_manage(){

  if (typeof G_messages != 'undefined') {
    $(".message_shop_table .message_line").detach();
    $(".message_shop_table").hide();
    $(".message_shop_table_void").hide();
    $(".message_shop_table_next").hide();
    $(".message_shop_table_previous").hide();
    $(".message_shop_table_loading").hide();
    $.each(G_messages.result, function(i,message){
      $(".message_shop_table").append( tmpl('message_shop_table_line', message) );
    });
    if (G_messages.result.length == 0) $(".message_shop_table_void").show();
    else $(".message_shop_table").show();
  }

  if (typeof G_baskets != 'undefined') {
    $(".basket_shop_table .basket_line").detach();
    $(".basket_shop_table").hide();
    $(".basket_shop_table_void").hide();
    $(".basket_shop_table_next").hide();
    $(".basket_shop_table_previous").hide();
    $(".basket_shop_table_loading").hide();
    $.each(G_baskets.result, function(i,basket){
      $(".basket_shop_table").append( tmpl('basket_shop_table_line', basket) );
    });
    if (G_baskets.result.length == 0) $(".basket_shop_table_void").show();
    else $(".basket_shop_table").show();
  }

  if (typeof G_customers != 'undefined') {
    $(".customer_shop_table .customer_line").detach();
    $(".customer_shop_table").hide();
    $(".customer_shop_table_void").hide();
    $(".customer_shop_table_next").hide();
    $(".customer_shop_table_previous").hide();
    $(".customer_shop_table_loading").hide();
    $.each(G_customers.result, function(i,customer){
      $(".customer_shop_table").append( tmpl('customer_shop_table_line', customer) );
    });
    if (G_customers.result.length == 0) $(".customer_shop_table_void").show();
    else $(".customer_shop_table").show();
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
            diveboard.alert(I18n.t(["js","shop_page","A technical error occured while cropping the picture"]), data);
          }
        },
        error: function(data){
          diveboard.alert(I18n.t(["js","shop_page","A technical error occured while cropping the picture"]), data);
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
          // lang     : 'ru',
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
  if (window.location.hash == '#claim') show_shop_claim();
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
            diveboard.alert(I18n.t(["js","shop_page","A technical error occured while cropping the picture"]), data);
          }
        },
        error: function(data){
          diveboard.alert(I18n.t(["js","shop_page","A technical error occured while cropping the picture"]), data);
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
          $(".head_picture img").attr("src", me.element.find('.current_image img').attr("src"));
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
        diveboard.alert(I18n.t(["js","shop_page","The data could not be completely updated"]), data, function(){
        diveboard.unmask_file();
        //window.location.replace('/'+G_shop_api['vanity_url']);
        });
      } else {
        //detail the alert
        diveboard.alert(I18n.t(["js","shop_page","A technical error occured."]), data, function(){
          diveboard.unmask_file();
        });
      }
    },
    error: function(data) {
      diveboard.alert(I18n.t(["js","shop_page","A technical error occured while saving the dive. Please make sure your internet connection is up and try again."]), null, function() {
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
    colHeaders: [I18n.t(["js","shop_page","Category"]), I18n.t(["js","shop_page","Title"]), I18n.t(["js","shop_page","Description"]), I18n.t(["js","shop_page","Price"]), I18n.t(["js","shop_page","Tax (%)"]), I18n.t(["js","shop_page","Total price"]), "", "", I18n.t(["js","shop_page","Move"]), ""],
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
  var full_data = this.element.find(".dive_list_edit").handsontable("getData");
  var data_to_send = [];
  var validity = true;

  $.each(full_data, function(i,e){
    e.order_num = i;
    if (e.hasChanged == null) return;
    data_to_send.push(e);
    validity = validity && me.validateRow(e);
  });

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
        diveboard.alert(I18n.t(["js","shop_page","The data could not be completely updated"]), data, function(){
        diveboard.unmask_file();
        //window.location.replace('/'+G_shop_api['vanity_url']);
        });
      } else {
        //detail the alert
        diveboard.alert(I18n.t(["js","shop_page","A technical error occured."]), data, function(){
          diveboard.unmask_file();
        });
      }
    },
    error: function(data) {
      diveboard.alert(I18n.t(["js","shop_page","A technical error occured while saving the data. Please make sure your internet connection is up and try again."]), null, function() {
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

  var button_down = $("<button class='grey_button_small down_spreadsheet_line'>"+I18n.t(["js","shop_page","Down"])+"</button>");
  var button_up = $("<button class='grey_button_small up_spreadsheet_line'>"+I18n.t(["js","shop_page","Up"])+"</button>");
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

  var button = $("<button class='grey_button_small delete_spreadsheet_line'>"+I18n.t(["js","shop_page","Delete"])+"</button>")
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

WidgetSpreadsheet.HtmlFieldEditor = function(instance, td, row, col, prop, value, cellProperties){

  $(td).off('dblclick.editor');
  $(td).on('dblclick.editor', function(){
    WidgetSpreadsheet.HtmlFieldEditorWidget(instance, td, row, col, prop, value, cellProperties)});

  $(td).on("keydown.editor", function (event) {
    console.log("eee"+event.keyCode);
    //if delete or backspace then empty cell
    if ([8, 46].indexOf(event.keyCode)>=0) {
      if (instance.getData()[row].description !== null)
        instance.getData()[row].hasChanged = true;
      instance.getData()[row].description = null;
      return;
    }

    //On enter or F2 or any printable key then open editor (key is lost though....)
    if ([13, 113].indexOf(event.keyCode)<0 && !Handsontable.helper.isPrintableChar(event.keyCode)) return;
    WidgetSpreadsheet.HtmlFieldEditorWidget(instance, td, row, col, prop, value, cellProperties);
  });

  return(function(){
    console.log('off');
    $(td).off('dblclick.editor');
    $(td).off('keydown.editor');
  });
}

WidgetSpreadsheet.HtmlFieldEditorWidget = function (instance, td, row, col, prop, value, cellProperties){
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


WidgetWidgetsEditor = function(dom){
  this.element = $(dom);
  this.initialized = false;
  if (!this.constructor.is_class_initialized && this.constructor.classInitialize)
    this.constructor.classInitialize();
}

WidgetWidgetsEditor.classInitialize = function(){
  $(".widget_preview.shop_medium").live('update', function(){
    var section = $(this);
    var w = parseInt(section.find(".controls .width").val());
    var wmin = parseInt(section.find(".controls .width").attr('min'));
    var wmax = parseInt(section.find(".controls .width").attr('max'));
    if (isNaN(w) || typeof(w) == 'undefined') {
      w = wmin;
      section.find(".controls .width").val(wmin);
    } else if (w < wmin) {
      w = wmin;
      section.find(".controls .width").val(wmin);
    } else if (w > wmax){
      w = wmax;
      section.find(".controls .width").val(wmax);
    }

    section.find(".widget_preview_iframe").attr("width", w);

    section.find('.html_preview').text("<iframe frameborder=0 scrolling='no' onload='this.height=this.contentWindow.document.body.scrollHeight+\"px\"' height='156px' width='"+w+"px' src='"+G_locale_root_url+"api/widget/shop_medium/"+G_shop_api.shaken_id+"'></iframe>");
  });

  $(".widget_preview.shop_large").live('update', function(){
    var section = $(this);
    var iframe = section.find('iframe')[0];
    var w = parseInt(section.find(".controls .width").val());
    var wmin = parseInt(section.find(".controls .width").attr('min'));
    var wmax = parseInt(section.find(".controls .width").attr('max'));
    if (isNaN(w) || typeof(w) == 'undefined') {
      w = wmin;
      section.find(".controls .width").val(wmin);
    } else if (w < wmin) {
      w = wmin;
      section.find(".controls .width").val(wmin);
    } else if (w > wmax){
      w = wmax;
      section.find(".controls .width").val(wmax);
    }

    var nb = section.find(".controls .nbreviews").val();
    try {
      section.find(".widget_preview_iframe").attr("width", w);
      section.find('.html_preview').text("<iframe frameborder=0 scrolling='no' onload='this.height=this.contentWindow.document.body.scrollHeight+\"px\"' height='"+(168+60*nb)+"px' width='"+w+"px' src='"+G_locale_root_url+"api/widget/shop_reviews/"+G_shop_api.shaken_id+"?n="+nb+"'></iframe>");

      var reviews = iframe.contentWindow.document.getElementsByClassName('review');
      for (var i = 0; i < reviews.length; i++)
        if (i < nb)
          reviews[i].style['display'] = 'block';
        else
          reviews[i].style['display'] = 'none';
      iframe.height = iframe.contentWindow.document.getElementsByClassName('widget')[0].scrollHeight + "px";
    } catch(e) {
    }
  });

  $(".widget_preview .controls input").live('change', function(){
    $(this).closest('.widget_preview').trigger('update');
  });

  this.is_class_initialized = true;
  //this code is run at most once, whatever the number of this kind of widgets on the page
}


WidgetWidgetsEditor.prototype.is_initialized = function(){
  return this.initialized;
  //prevents dom from being multi-initialized
}


WidgetWidgetsEditor.prototype.init = function(){
  this.initialized = true;
  this.element.find('.widget_preview').trigger('update');
}


WidgetWidgetsEditor.prototype.has_changed = function(){
  //tells the global save wether there is anything to do here
  return false;
}

WidgetWidgetsEditor.prototype.save = function(){
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
  initialize_review_reply();
}


WidgetReview.prototype.is_initialized = function(){
  return this.initialized;
  //prevents dom from being multi-initialized
}


WidgetReview.prototype.init = function(){
  this.initialized = true;

  if (typeof this.element.attr('data-widget_id') == 'undefined')
    this.element.attr('data-widget_id', G_shop_api['id']);

  //initialize standard display
  initialize_form_review({
    on_success: function(data){
      if (data.success && (data.error == null||data.error.length==0)){
        window.location.replace('/'+G_shop_api['vanity_url']);
      } else if (data.success) {
        diveboard.alert("The data could not be completely updated", data, function(){
          window.location.replace('/'+G_shop_api['vanity_url']);
        });

      } else {
        //detail the alert
        diveboard.alert("A technical error occured.", data, function(){
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



function staff_load(){

  $(".staff_page .staff_add_search").autocomplete({
    source: function(request, response){
      $(".staff_add_id").val("");
      $.ajax({
        url:"/api/search/user.json",
        data:({
          q: request.term
        }),
        dataType: "json",
        success: function(data){
          response( $.map( data, function( item ) {
            var lbl = item.label.replace(new RegExp("(?![^&;]+;)(?!<[^<>]*)(" + $.ui.autocomplete.escapeRegex(request.term) + ")(?![^<>]*>)(?![^&;]+;)", "gi"), "<strong>$1</strong>");
            return {
              label: "<div class='shop_add_staff_option'><img src='"+item.picture+"' class='profile_picture'/>"+"<span class='nickname'>"+lbl+"<br/>"+item.web.replace(/^http:\/\//,'')+"</span></div>",
              value: item.value,
              shaken_id: item.shaken_id,
              picture: item.picture
            }
          }));
        },
        error: function(data) { diveboard.alert(I18n.t(["js","shop_page","A technical error happened while trying to connect to Facebook."])); }
      });
    },
    minLength: 2,autoFocus: true,
    select: function(event, ui){
      $(".staff_add_id").val(ui.item.shaken_id);
      $(".staff_add_search").val(ui.item.label);
      $(".staff_add_search").removeClass('error');
    },
    close: function(event, ui){}//if ($(".staff_add_id").val() == "") $(".staff_add_search").val("");}
  });

  $.ui.autocomplete.prototype._renderItem = function (ul, item) {
    return $("<li></li>")
      .data("item.autocomplete", item)
      .append("<a>" + item.label + "</a>")
      .appendTo(ul);
  };

  $(".staff_page .staff_fire_button").live('click', function(e){
    var id = $(this).closest(".staff_user").data('membership_id');
    diveboard.mask_file(true);
    diveboard.api_call_delete('membership', id, function(){
      window.location.href = window.location.href;
      window.location.reload(true);
    }, function(){
      diveboard.unmask_file(true);
    });
  });

  $(".staff_page .shop_claim_staff").live("click", function(){
    var user_id = $(".staff_add_id").val();
    var group_id = G_shop_api.user_proxy_id;
    if (user_id == "") {
      $(".staff_add_search").addClass('error');
      return;
    }
    diveboard.mask_file(true);
    diveboard.api_call('membership', {user_id: user_id, group_id: group_id, role:'admin'}, function(){
      window.location.href = window.location.href;
      window.location.reload(true);
    }, function(){
      diveboard.unmask_file(true);
    });

  });

  $(".staff_page .staff_user .staff_selector").live('change', function(){
    var id = $(this).closest(".staff_user").data('membership_id');
    var user_id = $(this).closest(".staff_user").data('user_id');
    var group_id = G_shop_api.user_proxy_id;
    var role = $(this).val();
    diveboard.mask_file(true);
    diveboard.api_call('membership', {id: id, role:role}, function(){
      window.location.href = window.location.href;
      window.location.reload(true);
    }, function(){
      diveboard.unmask_file(true);
    });
  });

}


