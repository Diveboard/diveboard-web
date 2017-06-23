changes_list = {};
message_id = null;
function stack_changes(elem)
{
  changes_list[$(elem).attr('id')] = elem;
  console.log(elem);
}

function save_changes()
{
  process_modal.display('processing');
  var args = {'id': $('#shop_id').val()};
  var args_flag = false;
  var args2 = {'shop_id': $('#shop_id').val(), 'authenticity_token': auth_token};
  var args2_flag = false;
  var services_flag = false;
  var ajax_called = false;

  for (var key in changes_list)
  {
    var split = key.substr(9);
    if (split == "country")
    {
      args['country_code'] = $(changes_list[key]).attr('shortname') == undefined ? "" : $(changes_list[key]).attr('shortname'); 
      args_flag = true;
    }
    else if (split == "affiliations")
    {
      var checkboxes = $('input:checked');
      var i = 0;
      var length = checkboxes.length;
      var affil = [];

      while (i < length)
      {
        if ($(checkboxes[i]).attr('name') == 'affiliations')
          affil.push($(checkboxes[i]).val().substr(5));
        i++;
      }
      args2['affiliation'] = affil;
      args2_flag = true;
    }
    else if (split == "lang")
    {
      var lang = [];
      var elems = $('#language-stack .grid-stack-item-content p');
      var i = 0;
      var length = elems.length

      while (i < length)
      {
        lang.push($(elems[i]).attr('data-code'));
        i++;
      }
      args2['language'] = lang;
      args2_flag = true;
    }
    else if (split == "staff")
    {
      var staff = [];
      var elems = $('#staff-stack .grid-stack-item-content p');
      var i = 0;
      var length = elems.length

      while (i < length)
      {
        staff.push($(elems[i]).html());
        i++;
      }
      args2['team'] = staff;
      args2_flag = true;
    }
    else if (split == "questions")
    {
      var questions = [];
      var elems = $('#faq_content li');
      var i = 0;
      var length = elems.length

      while (i < length)
      {
        var title = $(elems[i]).find('.title').val().trim();
        var description = $(elems[i]).find('.description').val().trim();

        if (title.length != 0 && description.length != 0)
          questions.push({'question': title, 'answer': description});
        i++;
      }
      args2['qa'] = JSON.stringify(questions);
      args2_flag = true;
    }
    else
    {
      args[split] = $(changes_list[key]).val();
      args_flag = true;
    }
  }
  
  // Services Section
  // New goods
  if ($('.new-item').length != 0)
  {
    var elems = $('.new-item');
    var i = 0;
    var length = elems.length;
    var data = {
      'shop_id': $('#shop_id').val(),
      'authenticity_token': auth_token
    };
    var array = [];
    while (i < length)
    {
      if ($(elems[i]).find('.title input').val().trim().length != 0)
      {
        var elem = $(elems[i]);
        array.push({'shop_id': $('#shop_id').val(),
                    'realm': 'dive',
                    'cat1': $(elem).find('.category select').val(),
                    'title': $(elem).find('.title input').val().trim(),
                    'description': $(elem).find('.description textarea').val().trim(),
                    'price': $(elem).find('.price input').val(),
                    'currency': $('.currency_select').val(),
                    'tax': $(elem).find('.tax input').val(),
                    'total': $(elem).find('.good_total_price').html(),
                    'order_num': ($(elem).attr('data-gs-y') + 1)
                  });
      }
      i++;
    }
    if (array.length != 0)
    {
      ajax_called = true;
      data['arg'] = JSON.stringify(array);
      $.ajax({
        url: '/api/V2/good',
        type: "POST",
        data: data
      });
    }
  }
  // Updated goods
  {
    var data = {
      'authenticity_token': auth_token
    };
    var arg = [];
    for (var key in updated_goods)
    {
      var elem = $('#' + key);
      if ($(elem).find('.title input').val().trim().length != 0)
      {
        arg.push({'id': key.replace('item-', ''),
                  'cat1': $(elem).find('.category select').val(),
                  'title': $(elem).find('.title input').val().trim(),
                  'description': $(elem).find('.description textarea').val().trim(),
                  'price': $(elem).find('.price input').val(),
                  'currency': $('.currency_select').val(),
                  'tax': $(elem).find('.tax input').val(),
                  'total': $(elem).find('.good_total_price').html()
                });
      }
    }
    data['arg'] = JSON.stringify(arg);
    if (arg.length != 0)
    {
      ajax_called = true;
      $.ajax({
        url: '/api/V2/good',
        type: "POST",
        data: data
      });
    }
  }
  // deleted goods
  {
    for (var key in deleted_goods)
    {
      ajax_called = true;
      $.ajax({
        url: '/api/V2/good/' + key.replace('item-', ''),
        type: "DELETE"
      });
    }
  }
  // changed currency
  if (currency != $('.currency_select').val())
  {
    var new_currency = $('.currency_select').val();
    var elems = $('.services-stack .grid-stack-item');
    var i = 0;
    var length = elems.length
    var data = {
      'authenticity_token': auth_token
    };
    var arg = [];
    while (i < length)
    {
      if ($(elems[i]).attr('id') != undefined)
      {
        arg.push({'id': $(elems[i]).attr('id').replace('item-', ''), 'currency': new_currency});
      }
      i++;
    }
    if (arg.length != 0)
    {
      ajax_called = true;
      data['arg'] = JSON.stringify(arg);
      $.ajax({
        url: '/api/V2/good',
        type: "POST",
        data: data
      });
      var data = {
          'authenticity_token': auth_token,
          'arg': JSON.stringify({'id': $('#shop_id').val(), 'currency': $('.currency_select').val()})
        };
      $.ajax({
        url: '/api/V2/shop',
        type: "POST",
        data: data
      });
    }
  }
  // Update goods order
  {
    var data = {
      'authenticity_token': auth_token
    };
    var arg = [];
    var elems = $('.services-stack .grid-stack-item');
    var i = 0;
    var length = elems.length;
    while (i < length)
    {
      elem = $(elems[i]);
      if ($(elem).attr('id') != undefined && $(elem).attr('order_num') != ($(elem).attr('data-gs-y') + 1)) 
        arg.push({'id': $(elem).attr('id').replace('item-', ''), 'order_num': ($(elem).attr('data-gs-y') + 1)});
      i++;
    }
    if (arg.length != 0)
    {
      ajax_called = true;
      data['arg'] = JSON.stringify(arg);
      $.ajax({
        url: '/api/V2/good',
        type: "POST",
        data: data
      });
    }
  }

  if (args_flag == true)
  {
    ajax_called = true;
    var data = {
      'arg': JSON.stringify(args)
    };
    $.ajax({
      url: '/api/V2/shop',
      type: "POST",
      data: data
    });
  }
  if (args2_flag == true)
  {
    ajax_called = true;
    $.ajax({
      url: '/api/shopdetails/edit',
      type: "POST",
      data: args2
    });
  }
  if (ajax_called == false)
  {
    var location = window.location.href;
    var idx = location.indexOf('/edit');
    location = location.substr(0, idx);
    window.location.href = location; 
  }
  $(document).ajaxStop(function()
  {
    var location = window.location.href;
    var idx = location.indexOf('/edit');
    location = location.substr(0, idx);
    window.location.href = location;
  });
}

$(document).ready(function(){
  $('.slides input, select, textarea, .language-stack, .staff-stack').bind('change', function()
    {
      // exclude goods section
      if ($(this).closest('.goods').length != 0)
        return ;
      if ($(this).attr('type') == 'checkbox' && $(this).attr('name') == 'affiliations')
      {
        changes_list['shopedit_affiliations'] = 1;
        return ;
      }
      else if ($(this).attr('id') == 'language-stack' || $(this).attr('id') == 'shopedit_lang')
      {
        changes_list['shopedit_lang'] = 1;
        return ;
      }
      else if ($(this).attr('id') == 'staff-stack' || $(this).attr('id') == 'shopedit_staff')
      {
        changes_list['shopedit_staff'] = 1;
        return ;
      }
      stack_changes(this);
    });
  /*$('.language-stack, .staff-stack').on('change', function()
  {
    stack_changes(this);
  });*/

  $("#sign_select_all").click(function(e){
    e.preventDefault();
    $(".signature_table input").attr("checked", true);
  });

 $("#sign_unselect_all").click(function(e){
    e.preventDefault();
    $(".signature_table input").removeAttr("checked");
  });

 $(".sign_one_dive").click(function(e){
    e.preventDefault();
    var sign_target = $(e.target).closest("li");
    var id_array = [sign_target.data("signature-id")];
    var action = null;
    if ($(e.target).hasClass("validate_sign_dive"))
      action = 1;
    else if ($(e.target).hasClass("reject_sign_dive"))
      action = 0;
    sign_target.find(".sign_actions").hide();
    sign_target.find(".sign_spinner").show();
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
  $(".sign_bulk_dive").click(function(e) {
    e.preventDefault();
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
      sign_target.find(".sign_spinner").show();
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

  $(".basket_shop_table_filter").on('change', function(){
    var optionSelected = $("option:selected", this);
    var json_filter = optionSelected.attr('data-value');
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
    $(".basket_shop_table_next").click(function(){
    var optionSelected = $("option:selected", this);
    var json_filter = optionSelected.attr('data-value');
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

  $(".basket_shop_table_previous").click(function(){
    if (G_baskets_previous.length <= 1) return;
    var optionSelected = $("option:selected", this);
    var json_filter = optionSelected.attr('data-value');
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

  $("body").on('change', ".basket_confirmation_action", function(){
    var action = $(".basket_confirmation_action").val();
    var form = $(this).closest('.basket_confirmation_form');
    form.find('.basket_confirmation_part').hide();
    form.find('.basket_confirmation_'+action).show();
  });

  $("body").on("click", ".basket_confirmation_confirm .send", function(){
    var form = $(this).closest('.basket_confirmation_confirm');
    var url = "/api/basket/manage/confirm";
    var basket_id = form.data('basket_id');
    if (form.find('.also_deliver:checked').val())
      url = "/api/basket/manage/deliver";


    $.ajax({
      url: url,
      type: "POST",
      data: {
        basket_id: basket_id,
        note: form.find('.note_text').val(),
        'authenticity_token': auth_token
      },
      success: function(data){
        if (data.success && data.error) {
          diveboard.alert(I18n.t(["js","shop_page","A technical error occured."]), data, function(){
            window.location = window.location.href;
          });
        } else if (data.success) {
          $("#shop_basket_modal .modal_body").load(G_shop_api.permalink+"/care/basket/"+basket_id, function(){
            try {
            } catch(e){}
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
        });
      }
    });
  });

  $("body").on("click", ".basket_confirmation_deliver .send", function(){
    var form = $(this).closest('.basket_confirmation_deliver');
    var url = "/api/basket/manage/deliver";
    var basket_id = form.data('basket_id');

    $.ajax({
      url: url,
      type: "POST",
      data: {
        basket_id: basket_id,
        note: form.find('.note_text').val(),
        'authenticity_token': auth_token
      },
      success: function(data){
        if (data.success && data.error) {
          diveboard.alert(I18n.t(["js","shop_page","A technical error occured."]), data, function(){
            window.location = window.location.href;
          });
        } else if (data.success) {
          $("#shop_basket_modal .modal_body").load(G_shop_api.permalink+"/care/basket/"+basket_id, function(){
            try {
            } catch(e){}
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
        });
      }
    });
  });

  $("body").on("click", ".basket_confirmation_ask_detail .send", function(){
    var form = $(this).closest('.basket_confirmation_ask_detail');
    var url = "/api/basket/manage/ask_detail";
    var basket_id = form.data('basket_id');

    var message = form.find('.note_text').val();
    if (!message || message.length<10) {
      diveboard.notify(I18n.t(["js","shop_page","Message validation"]), I18n.t(["js","shop_page","Your message must be at least 10 characters long."]));
      return;
    }

    $.ajax({
      url: url,
      type: "POST",
      data: {
        basket_id: basket_id,
        message: message,
        'authenticity_token': auth_token
      },
      success: function(data){
        if (data.success && data.error) {
          diveboard.alert(I18n.t(["js","shop_page","A technical error occured."]), data, function(){
            window.location = window.location.href;
          });
        } else if (data.success) {
          $("#shop_basket_modal .modal_body").load(G_shop_api.permalink+"/care/basket/"+basket_id, function(){
            try {
            } catch(e){}
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
        });
      }
    });
  });

  $("body").on("click", ".basket_confirmation_reject .send", function(){
    var form = $(this).closest('.basket_confirmation_reject');
    var url = "/api/basket/manage/reject";
    var basket_id = form.data('basket_id');

    var message = form.find('.note_text').val();
    if (!message || message.length<10) {
      notify(I18n.t(["js","shop_page","Message validation"]), I18n.t(["js","shop_page","Your message must be at least 10 characters long."]));
      return;
    }

    $.ajax({
      url: url,
      type: "POST",
      data: {
        basket_id: form.data('basket_id'),
        message: message,
        'authenticity_token': auth_token
      },
      success: function(data){
        if (data.success && data.error) {
          diveboard.alert(I18n.t(["js","shop_page","A technical error occured."]), data, function(){
            window.location = window.location.href;
          });
        } else if (data.success) {
          $("#shop_basket_modal .modal_body").load(G_shop_api.permalink+"/care/basket/"+basket_id, function(){
            try {
            } catch(e){}
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
        });
      }
    });
  });

  $(".basket_shop_table").on('click', ".basket_line", function(){
    var basket_id = $(this).data('basket_id');
    $("#shop_basket_modal .modal_body").load(G_shop_api.permalink+"/care/basket/"+basket_id, function(e){
      try {
        e.preventDefault();
        //history.pushState("", "", G_shop_api.permalink+"/care/message/"+message_id);
        var pos = document.getElementById(message_id).offsetTop+100;
        $('html,body').animate({scrollTop: pos}, 'fast');
      } catch(e){}

      shop_basket_modal.display("message");
    });
  });

  $(".fake_link").click(function(e){
    e.preventDefault();
  });

  $(".message_shop_table_filter").on('change', function(){
    var optionSelected = $("option:selected", this);
    var json_filter = optionSelected.attr('data-value');
    console.log(json_filter);
    //var json_filter = JSON.stringify(host);
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
  $('.message_shop_table').on('click', '.message_line', function(e){
    e.preventDefault();
    message_id = $(this).data('message_id');
    $("#shop_message_modal .modal_body").load(G_shop_api.permalink+"/care/message/"+message_id, function(e){
      try {
        e.preventDefault();
        //history.pushState("", "", G_shop_api.permalink+"/care/message/"+message_id);
        var pos = document.getElementById(message_id).offsetTop+100;
        $('html,body').animate({scrollTop: pos}, 'fast');
      } catch(e){}

      shop_message_modal.display("message");
    });
  });
  $(".shopMessageModal").on('change', ".shop_customer_history_filter", function(e){
    var optionSelected = $("option:selected", this);
    var json_filter = optionSelected.attr('data-value');
    console.log(json_filter);
    $("#shop_message_modal .modal_body").load(G_shop_api.permalink+"/care/message/"+message_id + "?filter_history=" + json_filter, function(e){
      try {
        e.preventDefault();
        //history.pushState("", "", G_shop_api.permalink+"/care/message/"+message_id);
        var pos = document.getElementById(message_id).offsetTop+100;
        $('html,body').animate({scrollTop: pos}, 'fast');
      } catch(e){}
    //window.location = "?filter_history="+$(this).val();
    });
  });






  $(".shopMessageModal").on('click', ".message_history_controls .reply_to", function(ev){
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

  $(".shopMessageModal").on('click', ".message_history .reply_message .cancel_group_inquiry", function(){
    $(this).closest('.reply_message').hide();
    $(this).closest('.message_history').parent().find('.message_history_controls').show();
  });

  $(".shopMessageModal").on('click',".history_item .mark_as_read", function(){
    var msgid = $(this).data('msgid');
    var msg_container = $(this).closest('.history_item');
    msg_container.addClass('status_change');
    api_call("message", {
        'id': msgid,
        'status': 'read'
      }, function(data){
        if (data && data.result && data.result.status == 'read') {
          msg_container.addClass('read');
          msg_container.removeClass('unread');
        }
        msg_container.removeClass('status_change');
      }, function(){
        msg_container.removeClass('status_change');
      }, 'public'
    );
  });

  $(".shopMessageModal").on('click', ".history_item .mark_as_unread", function(){
    var msgid = $(this).data('msgid');
    var msg_container = $(this).closest('.history_item');
    msg_container.addClass('status_change');
    api_call("message", {
        'id': msgid,
        'status': 'new'
      }, function(data){
        if (data && data.result && data.result.status == 'new') {
          msg_container.addClass('unread');
          msg_container.removeClass('read');
        }
        msg_container.removeClass('status_change');
      }, function(){
        msg_container.removeClass('status_change');
      }, 'public'
    );
  });

  $(".shopMessageModal").on('click', ".message_history_controls .mark_all_read", function(){
    var data_to_send = [];
    var list_elements = $(".message_received.unread").not(".status_change");
    list_elements.each(function(i,e){
      var msg_id = $(e).find(".mark_as_read").data('msgid');
      if (msg_id) data_to_send.push({'id':msg_id,'status':'read'});
    });

    if (data_to_send.length == 0) return;

    list_elements.addClass('status_change');

    api_call("message", data_to_send, function(data){
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


  $(".shopMessageModal").on("click", ".shop_message_to_customer .submit_group_inquiry", function(){
    var dlg = $(this).closest(".shop_message_to_customer");

    var title = dlg.find(".topic_text").val();
    if (!title || title.length<5) {
      notify($(this), I18n.t(["js","shop_page","Message validation"]), I18n.t(["js","shop_page","Your topic must be at least 5 characters long."]));
      return;
    }

    var message = dlg.find('.message_text').val();
    if (!message || message.length<10) {
      notify($(this), I18n.t(["js","shop_page","Message validation"]), I18n.t(["js","shop_page","Your message must be at least 10 characters long."]));
      return;
    }

    var reload_url = $(this).data('reload_url');

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

    api_call("message", data_to_send, function(){
      if (reload_url && dlg.closest(".tab_panel")) {
        dlg.closest(".tab_panel").load(reload_url, function(){
          init_content4_buy_manage();
        });
      } else {
        window.location.href = window.location.href;
        window.location.reload(true);
      }
    }, function(){
    }, 'public');

  });




init_content4_buy_manage();
});

function sign_dives(id_array, action_type ,callback_success, callback_fail){
  //if action_type == 1 -> sign
  //if action_type == 0 -> reject
  // will call /api/care/sign_dives
  console.log("test sign_dives");
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
          notify($(this), I18n.t(["js","shop_page","Error signing dive"]) ,data.error[0], callback_fail);
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
config_translate = function(section, key){
  try {
    if (typeof G_config_translate_labels[section][key] == 'undefined')
      return key;
    else
      return G_config_translate_labels[section][key];
  } catch(e) {return key;}
}
function api_call(class_name, data_to_send, success, error, flavour){
  $.ajax({
    url: '/api/V2/'+class_name,
    dataType: 'json',
    data: {
      arg: JSON.stringify(data_to_send),
      flavour: flavour || 'public',
      'authenticity_token': auth_token
    },
    type: "POST",
    success:  function(data){
      if (data.success && (data.error == null||data.error.length==0)){
        success(data);
      } else if (data.success) {
        notify($(this), I18n.t("Error"), I18n.t("The data could not be completely updated"), function(){
          error();
        });
      } else {
        //detail the alert
        diveboard.alert(I18n.t(["js","global","A technical error occured."]), data, function(){
          error();
        });
      }
    },
    error: function(data){
      diveboard.alert(I18n.t(["js","global","A technical error occured."]), data, function(){
        error();
      });
    }
  });
}
function notify(html, title, text, callback){
  html.closest(".message_history").find(".dialog-global-notify .dge-text").html(text);
  html.closest(".message_history").find(".dialog-global-notify").attr("title", title);
  html.closest(".message_history").find(".dialog-global-notify .ui-dialog-title").html(title);
  html.closest(".message_history").find(".dialog-global-notify").show();

}

$(document).ready(function(){
  $(".widget_preview.shop_medium").on('update', function(){
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

  $(".widget_preview.shop_large").on('update', function(){
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

  $(".widget_preview .controls input").on('change', function(){
    $(this).closest('.widget_preview').trigger('update');
  });
  $(".widget_preview.shop_large").trigger('update');
  $(".widget_preview.shop_medium").trigger('update');
});