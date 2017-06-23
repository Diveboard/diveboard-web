CommercialShop = function(){};
CommercialShop.initialize = function(){

  $(".main_features_area .left_menus li").click(function(){CommercialShop.show_slide($(this).data("slide_id")); });

}


CommercialShop.show_slide = function(n){
  $(".main_features_area .active").removeClass("active");
  $(".main_features_area .slide"+n).addClass("active");
}



CommercialShopSignup = function(){};

CommercialShopSignup.initialize = function(){
  $(".shop_search_name, .shop_search_location").bind('keyup', CommercialShopSignup.enqueueSearchExistingShop);
  $(".shop_search_name, .vanity_field input").bind('keyup', function(){
    var form = $(this).closest('.vanity_field');
    CommercialShopSignup.checkVanityUrl(form);
  });
  $(".create_shop_form").bind('submit', function(ev){
    var form = $(this).closest('.create_shop_form');
    if (!CommercialShopSignup.validateNewShop(form))
      ev.preventDefault();
  });
  $(".password_fields input").bind('keyup', function(){
    var form = $(this).closest('.password_fields');
    CommercialShopSignup.check_password(form);
  });
  $(".login_email_field input").bind('keyup', function(){
    var form = $(this).closest('.login_email_field');
    CommercialShopSignup.check_login_email(form);
  });


  $(".line_click_select_input tr").bind('click', function(){
    $(this).find('input').attr('checked', 'checked');
  });

  $(".paypal_checkout").bind('click', CommercialShopSignup.startPaypal);

  $(".autocomplete_country input").autocomplete({  source : countries,
    open: function(){
      $(this).attr("shortname","blank");
      $(this).closest('.autocomplete_country').find('img').attr("src","/img/flags/blank.gif");
    },
    select: function(event, ui) {
      //get spot details and show them
      //selected is ui.item.id
      $(this).closest('.autocomplete_country').find('img').attr("src","/img/flags/"+ui.item.name.toLowerCase()+".gif");
      $(this).closest('.autocomplete_country').find('.short_code').val(ui.item.name);
      $(this).attr("shortname",ui.item.name.toLowerCase());
    },
    close: function(event, ui){
    },
    change: function(event,ui){
      var guessed_code = country_code_from_name($(this).val());
      if ($(this).attr("shortname") == 'blank' && guessed_code != 'blank' && guessed_code != ''){
        $(this).closest('.autocomplete_country').find('img').attr("src","/img/flags/"+guessed_code.toLowerCase()+".gif");
        $(this).closest('.autocomplete_country').find('.short_code').val(guessed_code);
        $(this).attr("shortname",guessed_code.toLowerCase());
        $(this).val(country_name_from_code(guessed_code));
      } else if ($(this).attr("shortname") == 'blank') {
        $(this).val("");
        $(this).closest('.autocomplete_country').find('.short_code').val("");
      }
    },
    autoFocus:true
  });

  //Shop claim
  $(".claim_shop_manual_link").live('click', function(e){
    e.preventDefault();
    var form=$(this).closest('.shop_signup_step');
    form.find(".auto_claim").hide();
    form.find(".manual_claim").show();
  });

  $(".claim_shop_auto_link").live('click', function(e){
    e.preventDefault();
    var form=$(this).closest('.shop_signup_step');
    form.find(".auto_claim").show();
    form.find(".manual_claim").hide();
  });

}

CommercialShopSignup.validateNewShop = function(form){
  form.find(".mandatory").removeClass("error").each(function(i,e){
    var val = $(e).val();
    if (val == "") $(e).addClass("error");
  });
  if (form.find(".mandatory.error").length > 0 ) {
    return false;
  }
  return true;
}

CommercialShopSignup.enqueueSearchExistingShop = function(ev){
  var form = $(this).closest('.shop_search');
  CommercialShopSignup.searchExistingShop(form);
}

CommercialShopSignup.searchExistingShop = function(form){
  var q_val = form.find(".shop_search_name").val();
  var l_val = form.find(".shop_search_location").val();
  l_val.replace(/\s+/g,' ').replace(/^\s+|\s+$/g, '');
  q_val.replace(/\s+/g,' ').replace(/^\s+|\s+$/g, '');

  if (form.data("previous_l_val") == l_val.replace(/\s+/g,' ').replace(/^\s+|\s+$/g, '')
    && form.data("previous_q_val") == q_val.replace(/\s+/g,' ').replace(/^\s+|\s+$/g, ''))
    return;

  if (q_val.length <= 3 && l_val.length <= 3) {
    form.find(".shop_list_empty").hide();
    form.find(".shop_list_row").hide();
    form.find(".shop_list_no_search").show();
    form.find(".loading").hide();
    return;
  }

  form.find(".shop_list_empty").hide();
  form.find(".shop_list_row").hide();
  form.find(".shop_list_no_search").hide();
  form.find(".loading").show();

  var running_query = form.data('running_query');
  if (running_query) running_query.abort();

  //wait a bit before sending request and make sure only one is triggered
  if (diveboard.postpone_me(700)) return;

  running_query = $.ajax({
    url: "/api/search/shop.json",
    dataType: 'json',
    data: {
      q: q_val,
      l: l_val,
      'authenticity_token': auth_token
    },
    type: "POST",
    success: function(pre_data){
      form.data('running_query', null);
      form.data("previous_q_val", q_val.replace(/\s+/g,' ').replace(/^\s+|\s+$/g, ''));
      form.data("previous_l_val", l_val.replace(/\s+/g,' ').replace(/^\s+|\s+$/g, ''));

      //Filtering private shops
      data = []
      for (var i in pre_data)
        if (!pre_data[i]['private']) data.push(pre_data[i]);

      form.find(".shop_list_row").detach();
      for (var i in data) {
        shop_data = data[i];
        form.find(".shop_list").append(tmpl('shop_search_line', shop_data));
      }

      if (data.length > 0) {
        form.find(".shop_list_empty").hide();
        form.find(".shop_list_row").show();
        form.find(".shop_list_no_search").hide();
        form.find(".loading").hide();
      } else {
        form.find(".shop_list_empty").show();
        form.find(".shop_list_row").hide();
        form.find(".shop_list_no_search").hide();
        form.find(".loading").hide();
      }
    },
    error: function(xhr){
      if (xhr.readyState == 0 || xhr.status == 0) return; //ignoring aborted search
      form.data('running_query', null);
      form.find(".shop_list_empty").hide();
      form.find(".shop_list_row").hide();
      form.find(".shop_list_no_search").show();
      form.find(".loading").hide();
    }
  });
  form.data('running_query', running_query);
}

CommercialShopSignup.checkVanityUrl = function(form){
  var val = form.find("input").val();
  val = val.replace(/^ */, '').replace(/ *$/, '');
  var previous_val = form.data("previous_val");

  if (previous_val == val) return;
  if (val.length < 4) return;

  form.find(".ok").hide();
  form.find(".nok").hide();
  form.find(".search").show();

  var running_query = form.data('running_query');
  if (running_query) running_query.abort();

  //wait a bit before sending request and make sure only one is triggered
  if (diveboard.postpone_me(700)) return;

  running_query = $.ajax({
    url: '/api/check_vanity_url',
    type: "POST",
    dataType: 'json',
    data:{
      vanity: val,
      authenticity_token: auth_token
    },
    success:function(data){
      form.data('running_query', null);
      form.data("previous_val", val);
      if (data.success && data.available) {
        form.find(".ok").show();
        form.find(".nok").hide();
        form.find(".search").hide();
        form.find(".error_text").text('');
        form.find(".error").removeClass('error');
      } else {
        form.find(".ok").hide();
        form.find(".nok").show();
        form.find(".search").hide();
        form.find(".error_text").text(data.error);
      }
    },
    error: function(xhr){
      if (xhr.readyState == 0 || xhr.status == 0) return; //ignoring aborted search
      form.data('running_query', null);
      form.data("previous_val", null);
      form.find(".ok").hide();
      form.find(".nok").show();
      form.find(".search").hide();
      form.find(".error_text").text('Technical error');
    }
  });
  form.data('running_query', running_query);
}

CommercialShopSignup.validateNewShop = function(form){
  var name = form.find("[name='new_shop[name]']");
  var vanity = form.find("[name='new_shop[vanity]']");
  var vanity_check = !form.find(".vanity_field .nok").is(':visible') && !form.find(".vanity_field .search").is(':visible');
  var country_code = form.find("[name='new_shop[country_code]']");
  var city = form.find("[name='new_shop[city]']");
  var web = form.find("[name='new_shop[web]']");

  form.find(".error").removeClass('error');

  if (name.val().length < 4) name.addClass('error');
  if (vanity.val().length < 4) vanity.addClass('error');
  if (!vanity.val().match(/^[A-Za-z0-9\-\_\.]*$/)) vanity.addClass('error');
  if (!vanity.val().match(/[A-Za-z0-9]/)) vanity.addClass('error');
  if (!vanity_check) vanity.addClass('error');
  if (country_code.val() == '' || country_code.val() == 'BLANK') form.find("[name='new_shop[country]']").addClass("error");
  if (city.val().length < 4) city.addClass('error');

  return form.find('.error').length == 0;
}


CommercialShopSignup.startPaypal = function(){
  var has_option = $("input[name=option_id]").length > 0
  var option = $("input[name=option_id]:checked").val();

  diveboard.mask_file(true, {"z-index": 20000});

  $.ajax({
    url: '/login/register_pro/checkout',
    dataType: 'json',
    type: "GET",
    data: {
      option_id: option
    },
    success: function(data){
      if (data.success) {
        var dg = new PAYPAL.apps.DGFlow({
          trigger: "pro_subscribe_action",
          expType: 'light'
        });
        dg.startFlow(data.url);
      }
      else {
        diveboard.alert(I18n.t(["js","commercial_shop","A technical error occured while initialising the payment process with Paypal."]), data);
        diveboard.unmask_file({"background-color": "#000000"});
      }
    },
    error: function(data) {
      diveboard.alert(I18n.t(["js","commercial_shop","A technical error occured while initialising the payment process with Paypal."]));
      diveboard.unmask_file({"background-color": "#000000"});
    }
  });

}
CommercialShopSignup.check_password = function(form){
  if (form.find(".password").val().length == 0) {
  } else if (form.find(".password").val().length < 5 || form.find(".password").val().length > 20) {
    form.find(".password_ok").hide();
    form.find(".password_nok").show();
  } else {
    form.find(".password_ok").show();
    form.find(".password_nok").hide();
  }

  if (form.find(".password_confirmation").val().length == 0){
    form.find(".password_confirm_ok").hide();
    form.find(".password_confirm_nok").hide();
  } else if (form.find(".password_confirmation").val() != form.find(".password").val()) {
    form.find(".password_confirm_ok").hide();
    form.find(".password_confirm_nok").show();
  } else {
    form.find(".password_confirm_ok").show();
    form.find(".password_confirm_nok").hide();
  }
}

CommercialShopSignup.check_login_email = function(form) {
  console.log("XXX");
  var val = form.find("input").val();
  val = val.replace(/^ */, '').replace(/ *$/, '').toLowerCase();
  var previous_val = form.data("previous_val");

  if (previous_val == val) return;
  if (val.length < 4) return;

  form.find(".ok").hide();
  form.find(".nok").hide();
  form.find(".search").show();

  var running_query = form.data('running_query');
  if (running_query) running_query.abort();

  //wait a bit before sending request and make sure only one is triggered
  if (diveboard.postpone_me(700)) return;

  running_query = $.ajax({
    url: '/api/check_email',
    type: "POST",
    dataType: 'json',
    data:{
      email: val,
      authenticity_token: auth_token
    },
    success:function(data){
      form.data('running_query', null);
      form.data("previous_val", val);
      if (data.success && data.available) {
        form.find(".ok").show();
        form.find(".nok").hide();
        form.find(".search").hide();
        form.find(".error_text").text('');
        form.find(".error").removeClass('error');
      } else {
        form.find(".ok").hide();
        form.find(".nok").show();
        form.find(".search").hide();
        form.find(".error_text").text(data.error);
      }
    },
    error: function(xhr){
      if (xhr.readyState == 0 || xhr.status == 0) return; //ignoring aborted search
      form.data('running_query', null);
      form.data("previous_val", null);
      form.find(".ok").hide();
      form.find(".nok").show();
      form.find(".search").hide();
      form.find(".error_text").text(I18n.t(["js","commercial_shop","Technical error"]));
    }
  });
  form.data('running_query', running_query);
}