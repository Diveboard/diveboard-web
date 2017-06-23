
////////////////////////////////////////////////////
//
//  FORM FOR SUBMITTING REVIEW
//
////////////////////////////////////////////////////

function initialize_form_review(options)
{

  ga('send', {
    'hitType': 'event',
    'eventCategory': 'review',
    'eventAction': 'review_initiated',
    'nonInteraction': true
  });

  $("#dialog-enter-review").data('saved_form_review' , $("#dialog-enter-review").html());
  if (options.on_success){
    $("#dialog-enter-review").data('on_post_success', options.on_success);
    $("#dialog-enter-review").data('on_delete_success', options.on_success);
  }
  if (options.on_post_success)
    $("#dialog-enter-review").data('on_post_success', options.on_post_success);
  if (options.on_delete_success)
    $("#dialog-enter-review").data('on_delete_success', options.on_delete_success);
  if (options.on_cancel)
    $("#dialog-enter-review").data('on_cancel', options.on_cancel);

  if (!initialize_form_review.binded){
    initialize_form_review.binded = true;

    $(".select_overall").live('click', function(e){
      if (e) e.preventDefault();
      $('.select_overall').removeClass('active');
      $(this).addClass('active');
    });

    $("#dialog-enter-review .review_services .list_option").live('click', function(e){
      if (e) e.preventDefault();
      $('.review_services .list_option').removeClass('active');
      $(this).addClass('active');
    });

    $('.click_toggle_input').live('click', function(e){
      if(e) e.preventDefault();
      var field = $(this).parent().find('input');
      field.attr('checked', !field.attr('checked'));
    });

    $('.review_popup_cancel').live('click', function(e){
      if(e) e.preventDefault();
      if ($("#dialog-enter-review").data('on_cancel'))
        $("#dialog-enter-review").data('on_cancel')();
      $("#dialog-enter-review").dialog('close');
    });

    $('.review_popup_delete').live('click', function(e){
      if(e) e.preventDefault();
      $("#dialog-enter-review").dialog('close');
      delete_form_review();
    });

    $('.review_popup_post').live('click', function(e){
      if(e) e.preventDefault();

      if( $(".review_services div.active").attr('name') == undefined){
        diveboard.notify(I18n.t(["js","form_review","Missing info"]),I18n.t(["js","form_review","You need to tell us what <b>service</b> you've used.<br/>Please select one and try again."]));
        return;
      }
      if(!($("#recommend_yes").hasClass("active") || $("#recommend_no").hasClass("active"))) {
        diveboard.notify(I18n.t(["js","form_review","Missing info"]),I18n.t(["js","form_review","You need to tell us what <b>Overall opinion</b> you have.<br/>Please make up your mind wether you'd recommend this dive shop and try again."]));
        return;
      }

      $("#dialog-enter-review").dialog('close');
      post_form_review();
    });


    $('.review_popup_login').live('click', function(e){
      if(e) e.preventDefault();

      if( $(".review_services div.active").attr('name') == undefined){
        diveboard.notify(I18n.t(["js","form_review","Missing info"]),I18n.t(["js","form_review","You need to tell us what <b>service</b> you've used.<br/>Please select one and try again."]));
        return;
      }
      if(!($("#recommend_yes").hasClass("active") || $("#recommend_no").hasClass("active"))) {
        diveboard.notify(I18n.t(["js","form_review","Missing info"]),I18n.t(["js","form_review","You need to tell us what <b>Overall opinion</b> you have.<br/>Please make up your mind wether you'd recommend this dive shop and try again."]));
        return;
      }

      $("#dialog-enter-review").dialog('close');

      //diveboard.mask_file(true);

      var options = {
        form: $("#dialog-login-review"),
        callback: post_review_after_login,
        cancel: function(){
          if ($("#dialog-enter-review").data('on_cancel'))
            $("#dialog-enter-review").data('on_cancel')();
          $("#dialog-login-review").open();
        }
      };
      diveboardAccount.start(options);

      ga('send', {
        'hitType': 'event',
        'eventCategory': 'login',
        'eventAction': 'prompt_login_4_review',
        'nonInteraction': true
      });
    });
  }

  reset_form_review();
}

function post_review_after_login(data){
  G_user_api = data.user;
  $("#review_user_id").val(data.user.id);
  diveboard.api_call('search/review', {user_id: $("#review_user_id").val(), shop_id: $("#review_shop_id").val()}, function(d2){
    if (d2.result.length == 0){
      post_form_review();
    } else {
      diveboard.notify(I18n.t(["js","form_review","Enter a review"]), I18n.t(["js","form_review","You have already left a review. Please edit the existing one if you want to change your comments."]), function(){
        window.location.href = window.location.href;
        window.location.reload(true);
      });
    }
  });
}

function reset_form_review()
{
  var saved_form_review = $("#dialog-enter-review").data('saved_form_review');
  if (typeof(saved_form_review) == 'undefined')
    initialize_form_review();

  $("#dialog-enter-review").html(saved_form_review);

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
}

function post_form_review()
{
  var data_to_send = {
    'user_id': $("#review_user_id").val() || null,
    'shop_id': $("#review_shop_id").val() || null,
    'anonymous': $("#review_anonymous").is(':checked'),
    'recommend': !($("#recommend_no.active").length > 0),
    'mark_orga': $("input[name=star_orga]:checked").val() || null,
    'mark_friend': $("input[name=star_friend]:checked").val() || null,
    'mark_secu': $("input[name=star_secu]:checked").val() || null,
    'mark_boat': $("input[name=star_boat]:checked").val() || null,
    'mark_rent': $("input[name=star_rent]:checked").val() || null,
    'title': $("#review_form_title").val(),
    'comment': $("#review_form_comment").val(),
    'service': $(".review_services div.active").attr('name')
  };

  //only include the id if it is not blank
  if ($("#review_id").val() > 0)
    data_to_send['id'] = $("#review_id").val();

  //diveboard.mask_file(true);

  $.ajax({
    url: '/api/V2/review',
    dataType: 'json',
    data: {
      arg: JSON.stringify(data_to_send),
      'authenticity_token': auth_token
    },
    type: "POST",
    success: $("#dialog-enter-review").data('on_post_success'),
    error: function(data) {
      diveboard.alert(I18n.t(["js","form_review","A technical error occured while saving the dive. Please make sure your internet connection is up and try again."]), null, function() {
        diveboard.unmask_file();
      });
    }
  });

}




function delete_form_review()
{
  //only include the id if it is not blank
  var review_id = $("#review_id").val();
  if (review_id <= 0)
    diveboard.alert(I18n.t(["js","form_review","You cannot delete this review."]))

  //diveboard.mask_file(true);

  $.ajax({
    url: '/api/V2/review/'+review_id,
    dataType: 'json',
    data: {
      'authenticity_token': auth_token
    },
    type: "DELETE",
    success: $("#dialog-enter-review").data('on_delete_success'),
    error: function(data) {
      diveboard.alert(I18n.t(["js","form_review","A technical error occured while deleting the dive. Please make sure your internet connection is up and try again."]), null, function() {
        diveboard.unmask_file();
      });
    }
  });

}



function check_form_review_complete()
{
    var has_errors = false;
    $("#recommend_no, #recommend_yes, .review_services div, #review_form_title, #review_form_comment").removeClass('wizard_input_error');

    if ($("#recommend_no.active, #recommend_yes.active").length == 0) {
      $("#recommend_no, #recommend_yes").addClass('wizard_input_error');
      has_errors = true;
    }

    if ($(".review_services div.active").length == 0) {
      $(".review_services div").addClass('wizard_input_error');
      has_errors = true
    }

    if ($("#review_form_title").val().length > 0 && $("#review_form_title").val().length < 10) {
      $("#review_form_title").addClass('wizard_input_error');
      has_errors = true
    }
    if ($("#review_form_comment").val().length > 0 && $("#review_form_comment").val().length < 50) {
      $("#review_form_comment").addClass('wizard_input_error');
      has_errors = true
    }

    return(!has_errors);
}

function load_review_form(shop_home, reload_page){
  $("#dialog-enter-review").detach();
  $("#dialog-login-review").detach();

  //diveboard.mask_file(true);

  //Populating the form
  if ($("#form_review_holder").length == 0)
    $('body').append('<div id="form_review_holder"></div>');

  $("#form_review_holder").load((shop_home+'/form_review').split("/pro")[1], function(data){
    if (!data.match(/<div/i)) {
      diveboard.notify(data);
      diveboard.unmask_file();
      return;
    }

    initialize_form_review({
      on_post_success: function(data){
        if (data.success && (data.error == null||data.error.length==0)){
          diveboard.notify(I18n.t(["js","form_review","Review"]), I18n.t(["js","form_review","Your review has been correctly saved. Thanks !"]), function(){
            if (reload_page)
              window.location.reload();
            else
              diveboard.unmask_file();
          });
        } else if (data.success) {
          diveboard.alert(I18n.t(["js","form_review","The data could not be completely updated"]), data, function(){
            if (reload_page)
              window.location.reload();
            else
              diveboard.unmask_file();
          });

        } else {
          //detail the alert
          diveboard.alert(I18n.t(["js","form_review","A technical error occured."]), data, function(){
            diveboard.unmask_file();
          });
        }
      },
      on_delete_success: function(data){
        if (data.success && (data.error == null||data.error.length==0)){
          diveboard.notify(I18n.t(["js","form_review","Review"]), I18n.t(["js","form_review","Your review has been correctly deleted."]), function(){
            if (reload_page)
              window.location.reload();
            else
              diveboard.unmask_file();
          });
        } else if (data.success) {
          diveboard.alert(I18n.t(["js","form_review","The data could not be completely updated"]), data, function(){
            if (reload_page)
              window.location.reload();
            else
              diveboard.unmask_file();
          });

        } else {
          //detail the alert
          diveboard.alert(I18n.t(["js","form_review","A technical error occured."]), data, function(){
            diveboard.unmask_file();
          });
        }
      },
      on_cancel: function(){
        diveboard.unmask_file();
      }


    });

    $("#dialog-enter-review").dialog({
        resizable: false,
        modal: true,
        width: '700px',
        zIndex: 99999,
        buttons: {},
        close: function(){
          diveboard.unmask_file();
        }
    });
  });
}
