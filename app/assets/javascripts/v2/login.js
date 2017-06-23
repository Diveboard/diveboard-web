var auth_token;
var Login = {};

try {
  if (typeof(I18n) == 'undefined')
    I18n = {};
  if (!I18n.locale )
    I18n.locale = document.getElementsByTagName('HTML')[0].getAttribute("xml:lang");
} catch(e){
  console.log(e);
}

try {
  I18n = I18n||{};
  I18n.defaultSeparator=" |#i18n#| ";
  I18n.fallbacks=true;
  I18n.old_t = I18n.t;
  I18n.t = function(){
    var r = I18n.old_t.apply(this, arguments);
    //r = "&Dagger;"+r+"&Dagger;";
    return r;
  }

  I18n.interpolate = function(message, options) {
    options = this.prepareOptions(options);
    var matches = message.match(this.PLACEHOLDER)
      , placeholder
      , value
      , name
    ;

    if (!matches) {
      return message;
    }

    for (var i = 0; placeholder = matches[i]; i++) {
      name = placeholder.replace(this.PLACEHOLDER, "$1");

      value = options[name];

      if (!this.isValidNode(options, name) && name.match(/:/)){
        var func_name = name.replace(/:.*/,"");
        var func_arg = name.replace(/[^:]*:/,"");

        if (typeof options[func_name] == 'function'){
          value = options[func_name].apply(func_name, [func_arg, options]);
        } else {
          value = "[missing " + placeholder + " value]";
        }
      } else if (!this.isValidNode(options, name)) {
        value = "[missing " + placeholder + " value]";
      }

      regex = new RegExp(placeholder.replace(/\{/gm, "\\{").replace(/\}/gm, "\\}"));
      message = message.replace(regex, value);
    }

    return message;
  };

  I18n.link_to = function(href, is_option){
    if (!href && is_option)
      return function(arg, options){return options[arg.replace(/^ *| *$/gm, '')]};
    else if (!href)
      return function(arg, options){return arg};
    else if (is_option)
      return function(arg, options){ return "<a href='"+href+"'>"+options[arg.replace(/^ *| *$/gm, '')]+"</a>"}
    else
      return function(arg, options){ return "<a href='"+href+"'>"+arg+"</a>"}
  };

} catch(e){
  console.log(e);
}

function process_data_after_login(data)
{
  if (login_modal != undefined && login_modal.context != null)
  {
    if (login_modal.context.type == 'shop_review')
    {
      login_modal.context.data['user_id'] = data.user.id;
      $.ajax({
      url: login_modal.context.url,
      dataType: 'json',
      data: {
        arg: JSON.stringify(login_modal.context.data),
        'authenticity_token': data.token
      },
      type: "POST",
      async: false
    });
    }
    login_modal.context = null;
  }
}

$('body').on('submit', '.sign_in', function(ev){
  ev.preventDefault();
  var form = $(this);
  //diveboard.mask_file(true);
  //$("#sign_up_popup .login .error_message span").hide();
  user = new Object();
  user["email"]= $(this).first().find("form input[name=email]").val();
  user["password"]= $(this).first().find("form input[name=pass]").val();
  user['open_session'] = $(this).first().find("form input[name=remember]").prop('checked')?'long':'short';
  user['authenticity_token'] = auth_token;
//post login data
  $.ajax({
    url: "/api/login_email",
    dataType: 'json',
    data: user,
    type: "POST",
    error: function() {
      if (data.emailexists == false)
        $(this).first().find("form input[name=email]").addClass('invalid'); 
      else
        $(this).first().find("form input[name=pass]").addClass('invalid'); 
    },
    success: function(data){
      G_login_popup_locked = false;
      if(data.success){
          process_data_after_login(data);
          window.location.replace(document.URL.replace(window.location.hash, ''));
        return true;
      }
      else{
        if (data.emailexists == false)
          Login.setError(form, "email", data.error);
        else
          Login.setError(form, "pass", data.error);

        console.log(data);
      }
    }
  });
})

$('body').on('click', '.fb_sign_in', function(){
  var settings = {};
  settings.no_mask_file = true;
  settings.fb_perms='user_friends, email';
  settings.callback = function(){process_data_after_login(data);window.location.replace(document.URL.replace(window.location.hash, ''));}
  FB.login(function(response) {
    if (response.authResponse) {
      $.ajax({
        url: '/api/login_fb',
        type: 'POST',
        dataType: 'json',
        data: {
          'authenticity_token': auth_token,
          open_session: 'long', //todo: XXX check if remember me was clicked or not
          fbid: response.authResponse.userID,
          fbtoken: response.authResponse.accessToken,
          preferred_locale: I18n.locale,
          assign_vanity_url: true
        },
        success: function(data){
          console.log(data);
          if (data.success){
            if (data.new_account){
              ga('send', {
                'hitType': 'event',          // Required.
                'eventCategory': 'account',   // Required.
                'eventAction': 'register',      // Required.
                'eventLabel': 'facebook',
                'nonInteraction': true
              });
              process_data_after_login(data);
              window.location.replace(document.URL.replace(window.location.hash, ''));
            }
            else{
              if(data.contact_email==null){
                if(!data.email_permi){
                  console.log("in IIIIII");
                  FB.login(
                    function(response) {
                      console.log(response);
                      $.ajax({
                        url: '/api/update_contact_email',
                        type: 'POST',
                        dataType: 'json',
                        data: {
                          fbid: response.authResponse.userID,
                          fbtoken: response.authResponse.accessToken,
                        },
                        success: function(data){
                          process_data_after_login(data);
                          window.location.replace(document.URL.replace(window.location.hash, ''));
                        },
                        error: function(data){
                          process_data_after_login(data);
                          window.location.replace(document.URL.replace(window.location.hash, ''));
                        }
                      });
                    },
                    {
                      scope: 'email',
                      auth_type: 'rerequest'
                    }
                  );
                }
              }
              else{
                process_data_after_login(data);
                window.location.replace(document.URL.replace(window.location.hash, ''));
              }
            }

          } else {

          }
        },
        error: function(data){
        }
      });

    } else {
    }
  }, {scope: settings.fb_perms});
})
$('body').on('submit', '.sign_up', function(ev){
  ev.preventDefault();
  var form = $(this);
  var terms = $(this).find('[name="terms"]');
  if (terms.length == 1 && $(terms)[0].checked == false)
  {
    $(form).find('.terms').addClass('error');
    return ;
  }

  var data_to_send = {
    'email': $(this).first().find("form input[name=email]").val(),
    'nickname': $(this).first().find("form input[name=nickname]").val(),
    'password': $(this).first().find("form input[name=pass]").val(),
    'newsletter': true,
    'open_session': 'long',
    'assign_vanity_url': true,
    'preferred_locale': I18n.locale,
    'password_check': $(this).first().find("form input[name=pass]").val(),
    'authenticity_token': auth_token,
    utf8: "&#x2713;"
  }

  $.ajax({
    url: '/api/register_email',
    dataType: 'json',
    data: data_to_send,
    type: "POST",
    success: function(data){
      if (data.success){
        if (data.new_account)
        {
          ga('send', {
            'hitType': 'event',          // Required.
            'eventCategory': 'account',   // Required.
            'eventAction': 'register',      // Required.
            'eventLabel': 'email',
            'nonInteraction': true
          });
          process_data_after_login(data);
          window.location.replace(document.URL.replace(window.location.hash, ''));
        }
      }
      else{
        Login.clearError(form);
        for (var i = 0; i < data.errors.length; i++) {
          console.log(data.errors[i]);
          if(data.errors[i].params == 'email')
            Login.setError(form, "email", data.errors[i].error);

          else if(data.errors[i].params == 'nickname')
            Login.setError(form, "nickname", data.errors[i].error);

          else if(data.errors[i].params == 'password_check' || data.errors[i].params == 'password')
            Login.setError(form, "pass", data.errors[i].error);

        }
        login_modal._lightModalWinResize("login_modal");
      }
    },
    error: function(data){
      
    }
  });

});
Login.clearError = function(form){
  form.first().find("form input[name=\"nickname\"]").removeClass("invalid");
  form.first().find("form input[name=\"email\"]").removeClass("invalid");
  form.first().find("form input[name=\"pass\"]").removeClass("invalid");

  form.first().find("form .nickname_error").html("");
  form.first().find("form .email_error").html("");
  form.first().find("form .pass_error").html("");
}
Login.setError = function(form, error_tag, message){
  error_input = form.first().find("form input[name="+ error_tag +"]");
  error_msg = form.first().find("form ."+ error_tag +"_error");

  error_input.addClass('invalid'); 
  error_msg.html(message);
}


$( function() {
  try {
    auth_token = $("meta[name='csrf-token']").attr("content");
  }catch (err){
  }

  try{
    $.ajaxSetup({
      beforeSend: function(xhr) {
        xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
      }
    });
  }catch (err){
  }
});

 $('body').on('submit', '.reset_pass', function(ev){
  ev.preventDefault();
  var form = $(this);
  $(this).first().find(".reset_pass_success").css('display', 'none');
  $.ajax({
    url: "/api/reset_password",
    dataType: 'json',
    data: ({
      'authenticity_token': auth_token,
      utf8: "&#x2713;",
      email: $(this).first().find("form input[name=reset_login]").val()
    }),
    type: "POST",
    error: function() {
      if(data && data.error_code)
        console.log(data.error_code);
    },
    success: function(data){
      console.log(data);
      if(data.success)
        form.first().find(".reset_pass_success").css('display', 'block');
      else{
        Login.setError(form, "reset_login", data.error);
      }
    }
  });
});