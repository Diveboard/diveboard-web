/////////////////////////
///
///  INITIALISATION
///
/////////////////////////

var auth_token;

//Console.log checking
if (!("console" in window) || !("firebug" in console) && typeof console !== "object") {
 var names = ["log", "debug", "info", "warn", "error", "assert", "dir", "dirxml", "group", "groupEnd", "time", "timeEnd", "count", "trace", "profile", "profileEnd"];
 window.console = {};
 for (var i = 0, len = names.length; i < len; ++i) {
 window.console[names[i]] = function(){};
 }
}

jQuery.fn.outerHTML = function(s) {
    return s
        ? this.before(s).remove()
        : jQuery("<p>").append(this.eq(0).clone()).html();
};

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

function setDataAttribute(hash, path, val) {
  if (path.length <= 1) {
    hash[path[0]] = val;
  }
  else {
    if (!(path[0] in hash)) {
      hash[path[0]] = {};
    }
    setDataAttribute(hash[path[0]], path.splice(1), val);
  }
}

$(function(){
  flash_notif = new diveboard.flash($('.flash_notifications'), 8000, 2000)
});


$( function() {
  try {
    auth_token = $("meta[name='csrf-token']").attr("content");
  }catch (err){
    track_exception_global(err);
  }

  try{
    $.ajaxSetup({
      beforeSend: function(xhr) {
        xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
      }
    });
  }catch (err){
    track_exception_global(err);
  }

  try {
    initialize_login_popup();
  }catch (err){
    track_exception_global(err);
  }

  try {
    Header.initialize_inbox();
  }catch (err){
    track_exception_global(err);
  }

  try {
    Header.initialize_header();
  } catch(e){}

  try {
    generate_plugin_object();
    autodetect_plugin_download();
    autodetect_computer();
  } catch(err) {
    track_exception_global(err);
  }

  try{
    if (plugin())
      plugin().setLogLevel(G_LOG_LEVEL);
  } catch(err){
    //ERCK: OK do nothing here...
  }

  try {
    window.onerror=function(a, b, c) {
      try {
        if (console && console.log)
          console.log('1');
        $.get( '/api/js_logs', { "message": a, "page": b, "line": c, "location": window.location.href});
      } catch(err) {
        if (console && console.log)
          console.log(err);
      }
    };
  } catch(err) {
    track_exception_global(err);
  }


  try {
    initialize_language_selector()
  } catch(err) {
    track_exception_global(err);
  }

  //Adding catch exception to event bindings
  /*try {
    var jQueryBind = jQuery.fn.bind;
    jQuery.fn.bind = function( type, data, fn ) {
      if ( !fn && data && typeof data == 'function' )
      {
        fn = data;
        data = null;
      }
      //there is some issue with the sortable & draggable JqueryUI widget
      if ( fn && type.indexOf('move.sortable')<0 && type.indexOf('move.draggable')<0 )
      {
        var origFn = fn;
        var wrappedFn = function() {
          try
          {
            return(origFn.apply( this, arguments ));
          }
          catch ( ex )
          {
            track_exception_global(ex);
            // re-throw ex iff error should propogate
            // throw ex;
          }
        };
        fn = wrappedFn;
      }
      return jQueryBind.call( this, type, data, fn );
    };
  } catch(err) {}*/

  //Adding catch exception to event bindings through 'live'
  try {
    var jQueryLive = jQuery.fn.live;
    jQuery.fn.live = function( type, data, fn, internal ) {
      if ( !fn && data && typeof data == 'function' )
      {
        fn = data;
        data = null;
      }
      if ( fn )
      {
        var origFn = fn;
        var wrappedFn = function() {
          try
          {
            return( origFn.apply( this, arguments ));
          }
          catch ( ex )
          {
            track_exception_global(ex);
            // re-throw ex iff error should propogate
            //throw ex;
          }
        };
        fn = wrappedFn;
      }
      return jQueryLive.call( this, type, data, fn, internal );
    };
  } catch(err) {
    if (console && console.log)
      console.log(err.message);
  }

  try {
    $('body').mouseenter(function(){
      try {
        if (!G_autodetect_running)
          autodetect_computer();
      } catch(err) {
        track_exception_global(err);
      }
    });
  } catch(err) {
    track_exception_global(err);
  }

  try {
    $(".make_sudo_link").live('click', function(e){
      e.preventDefault();
    });
  } catch(err) {
    track_exception_global(err);
  }

  try {
    initialize_sudo();
  } catch(err) {
    track_exception_global(err);
  }

  try {
    initialize_dropdowns();
  } catch(err){
    track_exception_global(err);
  }

  try {
    initialize_local_timezones();
  } catch(err){
    track_exception_global(err);
  }

  try {
    initialize_global_basket();
  } catch(err){
    track_exception_global(err);
  }

  try {
    initialize_svg_icons();
  } catch(err){
    track_exception_global(err);
  }

  //Overload the browser history functions so that pages get reloaded correctly
  try {
    (function(){
      var G_current_page = window.location.pathname;
      var previous_pushState = window.history.pushState;
      var previous_replaceState = window.history.replaceState;

      window.history.pushState = function(arg1, arg2, url){
        previous_pushState.apply(this, arguments);
        G_current_page = window.location.pathname;
      }
      window.history.replaceState = function(arg1, arg2, url){
        previous_replaceState.apply(this, arguments);
        G_current_page = window.location.pathname;
      }
      window.addEventListener("popstate", function(e) {
        if (window.location.pathname !== G_current_page) {
          diveboard.mask_file(true);
          window.location = window.location.href;
        }
      });

    })();
  } catch(err){
    track_exception_global(err);
  }

  try {
    $("#idx_3_top .form_submit_button").bind('click', function(ev){
      ev.preventDefault();
      $(this).closest('form').submit();
    });
  } catch(err){
    track_exception_global(err);
  }

});


function track_exception_global(ex, context)
{
  if (typeof context == undefined) context = true;

  //note : 'for (var i in window)' may list all global variables....
  G_LAST_EXCEPTION = ex;
  var debug_var = {
        "location": window.location.href,
        "message": ex.message
      };

  //Add the authenticity_token
  try {
        debug_var['authenticity_token'] = $("meta[name='csrf-token']").attr("content");
  } catch(e) {
    if (console && console.error)
      console.error(e.message);
  }

  //Let's try to add the stacktrace (if anything goes wrong, just give up the stack trace)
  try {
    debug_var["stack"] = printStackTrace({e: ex});
    if (debug_var["stack"] && debug_var["stack"].length > 0)
      debug_var["page"] = debug_var["stack"][0];
  } catch(e) {
    if (console && console.error)
      console.error(e.message);
  }

  //Let's try to add the global variables (but give up if there is any issue)
  try {
    if (context) {
      debug_var['globals'] = {};
      for ( var i in window ) {
        //We don't necessarily want everything, just what we can send as JSON
        if (typeof window[i] != 'function')
          try {
            debug_var['globals'][i] = JSON.stringify(window[i]);
          } catch(e1) {}
      }
    }
  } catch(e){
    if (console && console.error)
      console.error(e.message);
  }

  //Let's try to add navigator info
  try {
    if (context) {
      debug_var['navigator'] = {};
      for ( var i in navigator ) {
        try {
          var json = JSON.stringify(navigator[i], function(key,val){
                if (key != 'enabledPlugin')
                  return(val);
              });
          debug_var['navigator'][i] = json;
        } catch(ex) {
        }
      }
    }
  } catch(e) {
    if (console && console.error)
      console.error(e.message);
  }

  //Log
  try {
    if (console && console.error) {
      //console.error( ex.message );
      //console.error( debug_var );
    }
  } catch(e){
    //if we're here, there's not much more to be done....
  }

  //Notify Diveboard for fix
  try {
    $.post( '/api/js_logs', debug_var );
  } catch(e){
    if (console && console.error)
      console.error(e.message);
  }
}


var diveboard = {};

diveboard.flash = function(element, timeout, delay) {
  if (typeof timeout != 'undefined')
    this.timeout = timeout;
  if (typeof delay != 'undefined')
    this.delay = delay;
  element.hover(this.apply_this(this, this.keep_it));
  this.last_hover = new Date().getTime();
  this.target = element;
  //start the counting
  this.go_away();
};

diveboard.flash.prototype = $.extend(diveboard.flash.prototype,  {
  last_hover: null,
  timeout: 8000,
  delay: 2000,
  target: null,
  run: null,
  go_away: function() {
    this.run = null;
    var now = new Date().getTime();
    try {
      //this raises an exception with IE8.....
      if (this.target.is(':hover'))
        this.last_hover = new Date().getTime();
    } catch(e){}
    if (this.last_hover + this.timeout <= now)
      this.target.fadeOut(this.delay);
    else
      this.run = setTimeout( this.apply_this(this,this.go_away), Math.max( 100 + this.last_hover + this.timeout - now, 1000));
  },
  keep_it: function(e) {
    this.last_hover = new Date().getTime();
    if (!this.run) {
      this.target.stop();
      this.target.css('opacity', 1);
      this.go_away();
    }
  },
  //local function to keep 'this' in events
  apply_this: function(e,f){
    return function(){f.apply(e,arguments);};
  }
});


//maths helpers,koz we love digits
diveboard.round = function(text, digits){
  return Math.round(Number(text)*Math.pow(10,digits))/Math.pow(10,digits);
}

diveboard.floor = function(text, digits){
  return Math.floor(Number(text)*Math.pow(10,digits))/Math.pow(10,digits);
}

diveboard.isNumeric = function(obj){
  if (typeof(obj) == "undefined")
    return false;
  if (typeof(obj) == "number")
    return !isNaN(obj);
  if (typeof(obj) == "string")
    return(obj.match(/[0-9]/) && !isNaN(obj));
  return(false);
}

diveboard.isValidDate = function(obj){
  try {
    if (typeof(obj) == "object" && obj.constructor === Date && !isNaN(obj.getDate()))
      return true;
    if (typeof(obj) == "string") {
      if (!obj.match(/^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}$/)) return false
      var d = new Date(Date.parse(obj));
    console.log(d);
      return(!isNaN(d.getDate()));
    }
    return(false);
  }catch(e){
    return 0;
  }
}

diveboard.cookies = function(){
  var cookies = {};
  var ARRcookies=document.cookie.split(";");
  for (var i=0;i<ARRcookies.length;i++)
  {
    var key=ARRcookies[i].substr(0,ARRcookies[i].indexOf("="));
    var val=ARRcookies[i].substr(ARRcookies[i].indexOf("=")+1);
    key=key.replace(/^\s+|\s+$/g,"");
    cookies[key] = val;
  }
  return(cookies);
}

diveboard.delete_cookie = function(name){
  document.cookie = name + '=;path=/;expires=Thu, 01 Jan 1970 00:00:01 GMT;domain='+$("meta[name='db-cookie-domain']").attr("content");
}

diveboard.alert = function(text, error_data, callback) {
  if(error_data)
    track_exception_global(text, error_data);

  $( "#dialog-global-error .dge-text").html(text);
  try {
    if (error_data.error_tag == null) throw 'no, no, no';
    $('#dialog-global-error .dge-tag').html(error_data.error_tag);
    $('#dialog-global-error .dge-tagtext').show();
  } catch(e) {
    $('#dialog-global-error .dge-tag').html('000000000000000');
    $('#dialog-global-error .dge-tagtext').hide();
  }
  $( "#dialog-global-error" ).dialog({
      resizable: false,
      modal: true,
      width: '600px',
      zIndex: 99999,
      close: function(){
        if (typeof callback == 'function') callback.apply(this, []);
      },
      buttons: {
        "OK": function() {
          $( this ).dialog( "close" );
        }
      }
  });
  if(error_data)
    $( "#dialog-global-error .clear" ).show();
  else
    $( "#dialog-global-error .clear" ).hide();
}
diveboard.mask_file = function (loader, options){
  if($("#mask_file").length == 0){
    $(document.body).append("<div id='file_mask'><img src='/img/transparent_loader_3.gif' height='66px' width='66px' class='file_spinning' alt='#' /></div>")
  }

  if (!diveboard.mask_file.binded){
    diveboard.mask_file.binded = true;
    $(window).bind('resize', diveboard.mask_resize);
  }

  diveboard.mask_resize();

  if (loader ==true) {
    $(".file_spinning").show();
  }else{
    $(".file_spinning").hide();
  }

  //Apply css options
  if (typeof options == 'undefined') options = {'z-index':25000};
  $('#file_mask').css(options);

  //transition effect
  //$('#file_mask').fadeIn(200);
  //$('#file_mask').fadeTo("fast",0.6);
  $('#file_mask').show();
  $('#file_mask').css("width","100%");
  $('#file_mask').css("height","100%");
  $('#file_mask').css("opacity","0.6");
}

diveboard.mask_resize = function(){
  //Get the screen height and width
  //var maskHeight = $(window).height();
  //var maskWidth = $(window).width();

  var maskHeight = "100%";
  var maskWidth =  "100%";

  //Set heigth and width to mask to fill up the whole screen
  $('#file_mask').css({'width':maskWidth,'height':maskHeight, 'top':0, 'left':0 });
}

diveboard.unmask_file = function (options){
  $('#file_mask').hide();
  //Apply css options
  if (typeof options == 'undefined') options = {};
  $('#file_mask').css(options);
}

diveboard.notify = function(title, text, callback){
  $( "#dialog-global-notify .dge-text").html(text);
  $( "#dialog-global-notify").attr("title", title);
  $( "#dialog-global-notify .ui-dialog-title").html(title);
  $( "#dialog-global-notify" ).dialog({
      resizable: false,
      modal: true,
      title: title,
      width: '400px',
      zIndex: 99999,
      close: function(){
        if (typeof callback == 'function') callback.apply(this, []);
      },
      buttons: {
        "OK": function() {
          $( this ).dialog( "close" );
        }
      }
  });
  $(".ui-dialog").position({
   my: "center",
   at: "center",
   of:".ui-widget-overlay"
  });
}

diveboard.propose = function(title, text, actions){
  // actions are {"mytitle":function}
  diveboard.lock_scroll();
  buttons={}
  $.each(actions, function(index, value){
    buttons[index] = function(){$( this ).dialog( "close" ); value();};
  })
  $( "#dialog-global-notify .dge-text").html(text);
  $( "#dialog-global-notify").attr("title", title);
  $( "#dialog-global-notify" ).dialog({
      resizable: false,
      modal: true,
      width: '400px',
      title: title,
      zIndex: 99999,
      closeOnEscape: false,
      buttons: buttons,
      open: function(event, ui) { $(".ui-dialog-titlebar-close").hide(); },
      beforeClose: function(event, ui) {
               diveboard.unlock_scroll();
            }
  });
  $(".ui-dialog").position({
   my: "center",
   at: "center",
   of:".ui-widget-overlay"
  });
  $( "#dialog-global-notify .ui-dialog-titlebar-close" ).hide();

}


diveboard.postpone_me = function(time) {

  var caller = arguments.callee.caller;

  if (caller._db_self) return(false);

  if (caller._queue) clearTimeout(caller._queue);

  caller._queue = setTimeout(
    (function(f,o,a){
      return( function(){
        f._db_self = true;
        f._queue = null;
        f.apply(o,a);
        f._db_self = false;
      })
    })(caller, this, caller.arguments),
    time);

  return(true);
}


diveboard.postpone_me_load = function() {

  var caller = arguments.callee.caller;

  if (caller._db_self) return(false);

  $(window).load(
    (function(f,o,a){
      return( function(){
        f._db_self = true;
        f.apply(o,a);
        f._db_self = false;
      })
    })(caller, this, caller.arguments)
  );

  return(true);
}
//Disables the postpone_me_load function after window load...
$(window).load(function(){diveboard.postpone_me_load = function(){return(false)}});

//ensures some templates are loaded
diveboard.postpone_me_template = function(template_names, me) {
  if (typeof template_names === 'string') diveboard.postpone_me_template([template_names], me);

  var missing_templates = [];
  for (var i in template_names)
    if (!document.getElementById(template_names[i]))
      missing_templates.push(template_names[i]);

  if (missing_templates.length == 0) return(false);

  var caller = arguments.callee.caller;
  if (caller._db_self) return(true);

  var restart = (function(f,o,a){
      return( function(){
        f._db_self = true;
        f.apply(o,a);
        f._db_self = false;
      })
    })(caller, me, caller.arguments);

  diveboard.mask_file(true);

  $.each(missing_templates, function(i,template_name) {
    console.log("Loading template "+template_name);
    $.ajax({
      url: '/api/templates/'+template_name,
      dataType: 'text',
      success: function(data){
        var script = $("<script id='"+template_name+"' type='text/html'></script>");
        script.html(data);
        $("body").append(script);
        //restart the function
        diveboard.unmask_file();
        restart();
      }
    });
  });

  return(true);
}



diveboard.multi_ajax = function(args) {
  args['ajax'] = [];
  args['result'] = [];
  for (var i in args['calls']) {
    var proxy_args = $.extend({}, args['calls'][i]); //clone
    proxy_args['complete'] = function(){
      args['result'][i] = arguments;
      if (args['calls'][i]['complete'])
        args['calls'][i]['complete'].apply(this, arguments);
    }
    args['ajax'][i] = $.ajax(proxy_args);
  }
}

diveboard.api_call = function(class_name, data_to_send, success, error, flavour){
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
        diveboard.notify(I18n.t("Error"), I18n.t("The data could not be completely updated"), function(){
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

diveboard.api_call_delete = function(class_name, id, success, error){
  $.ajax({
    url: '/api/V2/'+class_name+'/'+id,
    dataType: 'json',
    data: {
      'authenticity_token': auth_token
    },
    type: "DELETE",
    success:  function(data){
      if (data.success && (data.error == null||data.error.length==0)){
        success(data);
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

diveboard.config_translate = function(section, key){
  try {
    if (typeof G_config_translate_labels[section][key] == 'undefined')
      return key;
    else
      return G_config_translate_labels[section][key];
  } catch(e) {return key;}
}



diveboard.validateEmail = function(email){
   var re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return re.test(email);
}


/////////////////////////
//
// PLUGIN FUNCTIONS
//
/////////////////////////

var G_autodetect_running = false;

function plugin()
{
  var PLUGIN = document.getElementById("plugin");
  if( PLUGIN && (PLUGIN.name == "DiveBoard Reader" || (PLUGIN.version && PLUGIN.logs))) return PLUGIN;
  //if(navigator.mimeTypes["application/x-diveboard"]) return navigator.mimeTypes["application/x-diveboard"];
}

function generate_plugin_object()
{
  //FF, Chrome, ...
  try {
    if (navigator.plugins && navigator.plugins["DiveBoard"]) {
      $("#pluginContainer").append('<object id="plugin" type="application/x-diveboard" class=hiddenObject ><param name="onload" value="pluginLoaded" /><param name="windowless" value="true" /></object>');
    }
  } catch(e) {}

  if (plugin()) return;

  //IE......
  try {
    if (window.ActiveXObject) {
      var control = null;
      control = new ActiveXObject('DiveBoardcom.DiveBoard');

      var version = 0;
      var MSIEOffset = navigator.userAgent.indexOf("MSIE ");
      if (MSIEOffset > 0) {
        version = parseFloat(navigator.userAgent.substring(MSIEOffset + 5, navigator.userAgent.indexOf(";", MSIEOffset)));
      }
      if (version >= 9)
        $("#pluginContainer").append('<object id="plugin" type="application/x-diveboard" class=hiddenObject ><param name="onload" value="pluginLoaded" /><param name="windowless" value="true" /></object>');
      else
        $("#pluginContainer").append('<object id="plugin" type="application/x-diveboard" class=hiddenObject data="" ><param name="onload" value="pluginLoaded" /><param name="windowless" value="true" /></object>');
    }
  } catch(e) {}
}


function plugin_addEvent(name, func){
  var obj = plugin();
  if (window.attachEvent) {
    obj.attachEvent("on"+name, func);
  } else {
    obj.addEventListener(name, func, false);
  }

  //Saving the attached events for debugging
  try {
    G_attached_events[name] = func;
  } catch(e){
    if (e instanceof ReferenceError) {
      G_attached_events = {}
      G_attached_events[name] = func;
    }
  }
}


function autodetect_plugin_download()
{
  try {
    var date_plugin = Date.parse(plugin().version.substr(17));

    if (date_plugin < 1357000000000) //1st jan 2013
    {
      $("#download_tray_icon").show();
      return(true);
    }
    else
    {
      $("#download_tray_icon").hide();
      return(false);
    }
  }
  catch (err) {}

}


function autodetect_computer()
{
  if (!G_autodetect_running) {
    G_autodetect_running = true;
    G_autodetect_started = new Date().getTime();
  }

  try
  {
    var askAutodetect = "yes";

    //checking if the auto detect function has been deactivated
    var ARRcookies=document.cookie.split(";");
    for (var i=0;i<ARRcookies.length;i++)
    {
      var key=ARRcookies[i].substr(0,ARRcookies[i].indexOf("="));
      var val=ARRcookies[i].substr(ARRcookies[i].indexOf("=")+1);
      key=key.replace(/^\s+|\s+$/g,"");
      if (key=="askAutodetect")
      {
        askAutodetect = val;
      }
    }

    if (CheckPlugin())
    {
      var prevent_scan = false;
      if (typeof G_prevent_scan == 'boolean')
        prevent_scan = G_prevent_scan;
      var prevent_dialog = false;
      if (!prevent_scan && plugin().status.state != "COMPUTER_NOT_STARTED" && plugin().status.state != "COMPUTER_FINISHED")
        prevent_scan = true;

      //Prevent scanning during video playback : it causes a choppy video playback
      if (!prevent_scan && $("#cee_box:visible").length > 0)
        prevent_scan = true;

      if (!prevent_dialog && $(".settings_save_box") != null)
        prevent_dialog = $(".settings_save_box").is(':visible');

      if (!prevent_dialog && $("#dialog").is(':visible') != null)
        prevent_dialog = $("#dialog").is(':visible');

      //only scan the ports if the plugin is not running
      //does not scan either when in a wizard or settings...
      if ( !prevent_scan && plugin().isComputerPluggedin())
      {
        $("#computer_tray_icon").show();
        if (askAutodetect == "yes" && !prevent_dialog)
        {
          //show confirmation popup
          document.cookie = "askAutodetect=asked;path=/;domain="+$("meta[name='db-cookie-domain']").attr("content");
          $( "#dialog-computer-detected" ).dialog({
            resizable: false,
            modal: true,
            width: 350,
            zIndex: 99999,
            buttons: {
              "Yes": function() {
                $( this ).dialog( "close" );
                document.location = "/"+G_user_vanity_url+"/new?bulk=computer";
              },
              "Not now": function() {
                document.cookie = "askAutodetect=no;path=/;domain="+$("meta[name='db-cookie-domain']").attr("content");
                $( this ).dialog( "close" );
              },
              "Do not ask me again": function() {
                var exdate=new Date();
                exdate.setDate(exdate.getDate() + 365*5);
                document.cookie = "askAutodetect=never;path=/;expires="+exdate.toUTCString()+";domain="+$("meta[name='db-cookie-domain']").attr("content");
                $( this ).dialog( "close" );
              }
            }
          });
        }
      }
      else if (!prevent_scan)
      {
        $("#computer_tray_icon").hide();
        //Reset the flag if the computer has been unplugged
        if (askAutodetect != "never")
        {
          document.cookie = "askAutodetect=yes;path=/;domain="+$("meta[name='db-cookie-domain']").attr("content");
        }
      }
    }

    //Update regularly only 2 seconds during the 5 first minutes (300000 ms) after load
    var curtime = new Date().getTime();
    if (G_autodetect_started > curtime - 300000) {
      setTimeout(autodetect_computer,2000);
    }
    else {
      G_autodetect_running = false;
    }
  }
  catch (err) {
    G_autodetect_running = false;
  }
}


///////////////////////////
//
// LOGIN
//
///////////////////////////

/*
function initialize_login_popup(){
  //move popup if resized
  $(window).resize(function(){
    if (G_login_popup_hook != null && $("#login_popup").is(':visible'))
      update_login_popup_position(G_login_popup_hook);
  });
  $(".login_popup .user_password").live('keypress',function (event){return submitenter(this,event);});

  $('.sign_in').live('click',ask_login); //enables sign in on all "class='sign_in'" items
  $('.sign_up').live('click',ask_register); //enables sign in on all "class='sign_in'" items

  $(".login_popup .login_button").live('click', function(e){
    e.preventDefault();
    attempt_login($(this));
  });
}*/

function request_login(cancel_function){
  diveboard.notify();
  diveboard.propose("you need to login","", {
        "Cancel": function() {
          $( this ).dialog( "close" );
          if(cancel_function)
            cancel_function()
        }});
  $("#dialog-global-notify").html($("#login_popup").outerHTML());
  $("#dialog-global-notify #login_popup").css({display: "block", left:"0", top: "0", position: "relative", margin: "0 auto"});
  $(".ui-dialog-titlebar-close").hide();
}


// Check the login/password
// if OK  & cookie is set, reload current page
var G_login_popup_locked = false;
var G_login_popup_hook = null;

function attempt_login(myfield){
  console.log("XXX");
  var login_form = myfield.closest('.login_popup');
  login_form.find(".loader").show();
  G_login_popup_locked = true;
  user = new Object();
  user["email"]= login_form.find(".user_email").val();
  user["password"]= login_form.find(".user_password").val();
//post login data
  $.ajax({
    url: "/login/user_login",
    dataType: 'json',
    data: ({
      'authenticity_token': auth_token,
      utf8: "&#x2713;",
      user: user,
      token: login_form.find(".token").val()
    }),
    type: "POST",
    error: function() {
      diveboard.unmask_file();
      login_form.find(".errormsg").text(I18n.t(["js","global","An error occured while submitting the login request. Please try again."]));
      login_form.find(".remember").show();
      login_form.find(".loader").hide();
      if (data.emailexists == false)
        login_form.find(".user_email").css("border","solid 1px #f6101e");
      else
        login_form.find(".user_email").css("border","");
      login_form.find(".user_password").css("border","solid 1px #f6101e");
    },
    success: function(data){
        diveboard.unmask_file();
        G_login_popup_locked = false;
        if(data.success)
          window.location.replace(data.redirect_to);
        else{
          login_form.find(".errormsg").text(data.error);
          login_form.find(".remember").show();
          login_form.find(".loader").hide();
          if (data.emailexists == false)
            login_form.find(".user_email").css("border","solid 1px #f6101e");
          else
            login_form.find(".user_email").css("border","");
          login_form.find(".user_password").css("border","solid 1px #f6101e");
        }


      }
    });

}

function attempt_facebook_login(){
  var settings = {};
  settings.no_mask_file = true;
  settings.fb_perms='user_friends';
  settings.callback = function(){window.location.replace(document.URL);}
  diveboard.mask_file(true);
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
          if (data.success){
            if (data.new_account)
              ga('send', {
                'hitType': 'event',          // Required.
                'eventCategory': 'account',   // Required.
                'eventAction': 'register',      // Required.
                'eventLabel': 'facebook',
                'nonInteraction': true
              });
            window.location.replace(document.URL);
          } else {
            diveboard.unmask_file();
          }
        },
        error: function(data){
          diveboard.unmask_file();
        }
      });

    } else {
      diveboard.unmask_file();
    }
  }, {scope: settings.fb_perms});


}


function toggle_login_popup(object){
  G_login_popup_hook = object;
  if(!G_login_popup_locked){
    if($("#login_popup").is(':visible'))
      close_login_popup();
    else
      open_login_popup(object);
  }
}

function close_login_popup(){
  $("#login_popup").hide();
  //console.log("hiding");
  $(document).unbind('click',popup_disable_on_click);
}

function open_login_popup(object){
  $("#login_popup .user_email").val("");
  $("#login_popup .user_password").val("");
  update_login_popup_position(object);
  //console.log("showing");
  $(document).bind('click',popup_disable_on_click);
}

function update_login_popup_position(object){

  var left = ($(object).offset().left+$(object).width()-$("#login_popup").outerWidth());
  //if(left > 930) left=930;
  //console.log(left);
  $("#login_popup").css("left",left+"px");
  $("#login_popup").css("top",($(object).offset().top+$(object).height())+"px");
  $("#login_popup").show();
}


var login_popup_offset;
var login_popup_max_x;
var login_popup_max_y;
var eve;
function popup_disable_on_click(e){
  eve = e;
  if($("#login_popup").is(':visible') && (e.pageX !=0 && e.pageY != 0)){
    login_popup_offset = $("#login_popup").offset();
    login_popup_max_x = login_popup_offset.left + $("#login_popup").outerWidth();
    login_popup_max_y = login_popup_offset.top + $("#login_popup").outerHeight();
    if((e.pageX < login_popup_offset.left || e.pageX > login_popup_max_x || e.pageY < login_popup_offset.top || e.pageY > login_popup_max_y) && !$(e.currentTarget).hasClass("sign_in"))
      toggle_login_popup(null);
  }
}
function ask_login(ev){
  if(ev){
    ev.preventDefault();
    ev.stopPropagation();
  }
  //toggle_login_popup(ev.target);

//  diveboard.sign_up.show();
}

function ask_register(ev){
  if(ev){
    ev.preventDefault();
    ev.stopPropagation();
  }
  //toggle_login_popup(ev.target);
  $("#sign_up_popup .active").removeClass("active");
  $("#sign_up_popup .register").addClass("active");
  $("#sign_up_popup").show();
}

function submitenter(myfield,e)
{
  console.log("YYY");
  var keycode;
  if (window.event) keycode = window.event.keyCode;
  else if (e) keycode = e.which;
  else return true;

  if (keycode == 13)
  {
    attempt_login($(myfield));
    return false;
  }
  else
    return true;
}


var diveboardAccount={};


diveboardAccount.start = function(options){

  var settings = {
    form: $("<div/>"),
    callback: function(data){
      if (data.redirect_to) {
        window.location.href = data.redirect_to;
      } else {
        window.location.href = window.location.href;
        window.location.reload(true);
      }
    },
    cancel: function(data){
      diveboard.unmask_file();
    },
    error: function(data){
      diveboard.notify(I18n.t(["js","global","Diveboard Login"]), I18n.t(["js","global","A technical error occured while loging you on Diveboard."]), data.error, function(){
        window.location.href = window.location.href;
        window.location.reload(true);
      });
    }
  }
  $.extend(settings, options);

  if (!diveboardAccount.initialized){
    diveboardAccount.initialized = true;
    $(".login_included_popup input").live('keyup', function(){
        diveboardAccount.validate($(this).closest('.login_included_popup'));
    });
  }

  settings.form.find('.login_cancel').unbind('click');
  settings.form.find('.login_cancel').bind('click', settings.callback);

  settings.form.find('.fb_login_inline').unbind('click');
  settings.form.find('.fb_login_inline').bind('click', function(){
    settings.form.dialog('close');
    diveboard.mask_file(true);
    diveboardAccount.fb_login(settings);
  });

  settings.form.find('.signup_button').unbind('click');
  settings.form.find(".signup_button").live('click', function(e){
    settings.form.dialog('close');
    diveboard.mask_file(true);
    diveboardAccount.create(settings);
  });

  settings.form.find('.signup_button').unbind('click');
  settings.form.find(".signin_button").live('click', function(e){
    settings.form.dialog('close');
    diveboard.mask_file(true);
    diveboardAccount.email_login(settings);
  });

  settings.form.find(".show_signin").unbind('click');
  settings.form.find(".show_signin").live('click', function(e){
    settings.form.find(".form_signin").show();
    settings.form.find(".form_signup").hide();
  });

  settings.form.find(".show_signup").unbind('click');
  settings.form.find(".show_signup").live('click', function(e){
    settings.form.find(".form_signup").show();
    settings.form.find(".form_signin").hide();
  });


  settings.form.dialog({
    resizable: false,
    modal: true,
    width: '700px',
    zIndex: 99999,
    buttons: {},
    close: function(){
      diveboard.unmask_file();
    }
  });
}


diveboardAccount.validate = function(form){
  var validations = {};

  form.find(".errormsg").hide();

  form.find(".email_search").hide();
  form.find(".email_ok").hide();
  form.find(".email_nok").hide();
  var email = form.find(".email").val();
  if (typeof email == "undefined") email = "";
  email = email.replace(/ /g, "");
  if (email.length == 0){
    validations.email = {
      result: false,
      rule: 'email_length',
      value: email
    };
  } else if (!email.match(/..*@..*\...*$/)){
    validations.email = {
      result: false,
      rule: 'email_format',
      value: email
    };
    form.find(".email_nok").show();
    form.find(".email_errormsg."+validations.email.rule).show();
  } else {
    validations.email = {
      result: true,
      value: email
    };
    form.find(".email_ok").show();
  }

  form.find(".nickname_search").hide();
  form.find(".nickname_ok").hide();
  form.find(".nickname_nok").hide();
  var nickname = form.find(".nickname").val();
  if (typeof nickname == "undefined") nickname = "";
  if (nickname.length == 0){
    validations.nickname = {
      result: false,
      rule: "nickname_length",
      value: nickname
    };
  } else if (nickname.length < 4){
    validations.nickname = {
      result: false,
      rule: "nickname_length",
      value: nickname
    };
    form.find(".nickname_nok").show();
    form.find(".errormsg."+validations.nickname.rule).show();
  } else if (nickname.length > 30){
    validations.nickname = {
      result: false,
      rule: "nickname_extra_length",
      value: nickname
    };
    form.find(".nickname_nok").show();
    form.find(".errormsg."+validations.nickname.rule).show();
  } else {
    validations.nickname = {
      result: true,
      value: nickname
    };
    form.find(".nickname_ok").show();
  }

  form.find(".password_search").hide();
  form.find(".password_ok").hide();
  form.find(".password_nok").hide();
  var password = form.find(".password").val();
  if (typeof password == "undefined") password = "";
  if (password.length == 0){
    validations.password = {
      result: false,
      rule: "password_length",
      value: password
    };
  } else if (password.length < 5){
    validations.password = {
      result: false,
      rule: "password_length",
      value: password
    };
    form.find(".password_nok").show();
    form.find(".errormsg."+validations.password.rule).show();
  } else if (password.length > 20){
    validations.password = {
      result: false,
      rule: "password_extra_length",
      value: password
    };
    form.find(".password_nok").show();
    form.find(".errormsg."+validations.password.rule).show();
  } else if (password.match(/ /)) {
    validations.password = {
      result: false,
      rule: "password_space",
      value: password
    };
    form.find(".password_nok").show();
    form.find(".errormsg."+validations.password.rule).show();
  } else {
    validations.password = {
      result: true,
      value: password
    };
    form.find(".password_ok").show();
  }

  form.find(".vanity_search").hide();
  form.find(".vanity_ok").hide();
  form.find(".vanity_nok").hide();
  var vanity = form.find(".vanity").val();
  if (typeof vanity != "undefined"){
    vanity = vanity.replace(/ /g, "");
    if (vanity.length == 0){
      validations.vanity = {
        result: false,
        rule: "vanity_length",
        value: vanity
      };
    } else if (!vanity.match(/[A-Za-z\.0-9\-\_]*/)){
      validations.vanity = {
        result: false,
        rule: "vanity_chars",
        value: vanity
      };
      form.find(".vanity_nok").show();
      form.find(".errormsg."+validations.vanity.rule).show();
    } else if (vanity.length < 3 || vanity.length > 40){
      validations.vanity = {
        result: false,
        rule: "vanity_length",
        value: vanity
      };
      form.find(".vanity_nok").show();
      form.find(".errormsg."+validations.vanity.rule).show();
    } else {
      validations.vanity = {
        result: true,
        value: vanity
      };
      form.find(".vanity_ok").show();
    }
  }

  validations.open_session = {
    result: true,
    value: (form.find(".open_session").prop('checked')?'long':'short')
  }

  validations.newsletter = {
    result: true,
    value: (form.find(".newsletter").prop("checked"))
  };

  return(validations)
}

diveboardAccount.create = function(settings){
  var form = settings.form.find(".form_signup");

  var val = diveboardAccount.validate(form);
  for (var k in val){
    if (!val[k].result)
      return false;
  }

  var data_to_send = {
    'email': val.email.value,
    'nickname': val.nickname.value,
    'password': val.password.value,
    'newsletter': val.newsletter.value,
    'open_session': val.open_session.value,
    'password_check': val.password.value
  }

  if (val.vanity)
    data_to_send['vanity_url'] = val.vanity.value;
  else
    data_to_send['assign_vanity_url'] = true;

  diveboard.mask_file(true);

  $.ajax({
    url: '/api/register_email',
    dataType: 'json',
    data: data_to_send,
    type: "POST",
    success: function(data){
      form.find(".errormsg").hide();
      form.find("input").removeClass('error');
      if (data.success){
        if (data.new_account)
          ga('send', {
            'hitType': 'event',          // Required.
            'eventCategory': 'account',   // Required.
            'eventAction': 'register',      // Required.
            'eventLabel': 'email',
            'nonInteraction': true
          });
        settings.callback.apply(window, [data]);
      } else {
        settings.form.dialog("open");
        for (var i in data.errors) {
          var err = data.errors[i];
          var msg = form.find(".errormsg."+err.code);
          msg.show();
          form.find("input."+err.params).addClass('error');
        }
      }
    },
    error: function(data){
      settings.error.apply(window, [data]);
    }
  });
};

diveboardAccount.email_login = function(settings){
  var form = settings.form.find(".form_signin");

  settings.form.find(".errormsg.login_password_wrong").hide();

  var data_to_send = {};
  data_to_send['authenticity_token'] = auth_token;
  data_to_send['email'] = form.find('.email').val();
  data_to_send['password'] = form.find('.password').val();
  data_to_send['open_session'] = form.find('.open_session').prop('checked')?'long':'short';

  diveboard.mask_file(true);
  $.ajax({
    url: '/api/login_email',
    dataType: 'json',
    data: data_to_send,
    type: "POST",
    success: function(data){
      if (data.success) {
        settings.callback.apply(window, [data]);
      } else{
        settings.form.dialog("open");
        settings.form.find(".errormsg.login_password_wrong").show();
      }
    },
    error: function(data){
      settings.error.apply(window, [data]);
    }
  });
};



diveboardAccount.fb_login = function(settings){
  diveboard.mask_file(true);
  settings.fb_perms='user_friends';
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
          assign_vanity_url: true
        },
        success: function(data){
          if (data.success){
            if (data.new_account)
              ga('send', {
                'hitType': 'event',          // Required.
                'eventCategory': 'account',   // Required.
                'eventAction': 'register',      // Required.
                'eventLabel': 'facebook',
                'nonInteraction': true
              });
            settings.callback.apply(window, [data]);
          } else {
            diveboard.unmask_file();
            settings.error.apply(window, [data]);
          }
        },
        error: function(data){
          diveboard.unmask_file();
          settings.error.apply(window,[data]);
        }
      });

    } else {
      diveboard.unmask_file();
      settings.form.dialog("open");
    }
  }, {scope: settings.fb_perms});
}


///////////////////////////
//
// HEADER
//
///////////////////////////
/*var Header = function(){};

Header.initialize_header = function(){
  G_user_menu_locked = false;
  G_user_menu_hook = null;
  G_useless_menu_locked = false;
  G_useless_menu_hook = null;
  Header.resize();
  $('.search_field').autoclear();
  $(".header_user_button").mousedown(Header.toggle_user_menu);
  $(".header_user_profile").mousedown(Header.toggle_user_menu);
  $(".useless_menu_container").mousedown(Header.toggle_useless_menu);
  $('.tooltiped-left').qtip({
    style: {
      tip: {corner: true},
      classes: "ui-tooltip-diveboard"
    },
    position: {
      at: "bottom center",
      my: "top right"
    },
    hide: {
             fixed: true,
             delay: 300
         }
  });
  $(window).bind('resize', Header.resize);
}

Header.resize = function(){
    var current_search_width = $("#idx_3_top .search_field").width();
    var current_right = 0;
    if ($("#idx_3_top .tray_container").length > 0)
      current_right = $("#idx_3_top .tray_container").offset().left + $("#idx_3_top .tray_container").width();
    else
      current_right = $("#idx_3_top form").offset().left + $("#idx_3_top form").width();
    var max_right = $("#idx_3_top .links").offset().left;
    var delta = max_right+current_search_width-current_right-15;
    $("#idx_3_top .search_field").css('width', delta);
}

Header.toggle_user_menu = function(ev){
  if(ev){
    ev.preventDefault();
    ev.stopPropagation();
    G_user_menu_hook = ev.target;
  }else{
    G_user_menu_hook = null;
  }
  if(!G_user_menu_locked){
    if($("#header_user_menu").is(':visible')){
      $("#header_user_menu").hide();
      //console.log("hiding");
      $(document).unbind('click',Header.user_menu_disable_on_click);
    }else{
      Header.update_header_user_menu_position(ev.target);
      //console.log("showing");
      $(document).bind('click',Header.user_menu_disable_on_click);
    }
  }
}
Header.user_menu_disable_on_click = function(ev){
  eve=ev;
  if($("#header_user_menu").is(':visible') && (ev.pageX !=0 && ev.pageY != 0)){
    var header_user_menu_offset = $("#header_user_menu").offset();
    var header_user_menu_max_x = header_user_menu_offset.left + $("#header_user_menu").outerWidth();
    var header_user_menu_max_y = header_user_menu_offset.top + $("#header_user_menu").outerHeight();
    if((ev.pageX < header_user_menu_offset.left || ev.pageX > header_user_menu_max_x || ev.pageY < header_user_menu_offset.top || ev.pageY > header_user_menu_max_y) && !$(ev.target).hasClass("header_user_button") && !$(ev.target).hasClass("header_user_profile") && !$(ev.target).hasClass("header_user_page"))
      {
        Header.toggle_user_menu(null);
      }
  }
}
Header.update_header_user_menu_position = function(object){
  var object = $(".header_user_button");
  var left = (object.offset().left+object.width()-$("#header_user_menu").width()) - 2;
  //console.log(left);
  $("#header_user_menu").css("left",left+"px");
  //$("#header_user_menu").css("top",($(object).offset().top+$(object).height())+"px");

  if(navigator.appVersion.match(/msie/i)){
    $("#header_user_menu").css("top","39px");
  }else if(navigator.userAgent.match(/firefox/i)){
    $("#header_user_menu").css("top","38px");
  }else{
    $("#header_user_menu").css("top","37px");
  }
  $("#header_user_menu").show();
}

Header.toggle_useless_menu = function(ev){
  if(ev){
    ev.preventDefault();
    ev.stopPropagation();
    G_useless_menu_hook = ev.target;
  }else{
    G_useless_menu_hook = null;
  }
  if(!G_useless_menu_locked){
    if($("#useless_user_menu").is(':visible')){
      $("#useless_user_menu").hide();
      //console.log("hiding");
      $(".useless_menu_container table").css("background", "transparent");
      $(document).unbind('click',Header.useless_menu_disable_on_click);
    }else{
      Header.update_useless_user_menu_position(ev.target);
      //console.log("showing");
      $(document).bind('click',Header.useless_menu_disable_on_click);
    }
  }
}
Header.useless_menu_disable_on_click = function(ev){
  eve=ev;
  if($("#useless_user_menu").is(':visible') && (ev.pageX !=0 && ev.pageY != 0)){
    var useless_user_menu_offset = $("#useless_user_menu").offset();
    var useless_user_menu_max_x = useless_user_menu_offset.left + $("#useless_user_menu").outerWidth();
    var useless_user_menu_max_y = useless_user_menu_offset.top + $("#useless_user_menu").outerHeight();
    if((ev.pageX < useless_user_menu_offset.left || ev.pageX > useless_user_menu_max_x || ev.pageY < useless_user_menu_offset.top || ev.pageY > useless_user_menu_max_y) && !$(ev.target).hasClass("useless_menu_container") && !$(ev.target).hasClass("useless_menu_stuff"))
      {
        $(".useless_menu_container").css("background", "transparent");
        Header.toggle_useless_menu(null);
      }
  }
}
Header.update_useless_user_menu_position = function(object){
  var object = $(".useless_menu_container");
  $("#useless_user_menu").css("left",0);
  var left = (object.offset().left+object.outerWidth()-$("#useless_user_menu").width())-2;
  //console.log(left);
  $("#useless_user_menu").css("left",left+"px");
  //$("#header_user_menu").css("top",($(object).offset().top+$(object).height())+"px");
  $("#useless_user_menu").css("top","37px");
  $("#useless_user_menu").show();
  $(".useless_menu_container table").css("background", "rgba(0, 0, 0, 0.9)");
  //$(".useless_menu_container").css("border","1px solid #999");
  //$(".useless_menu_container").css("border-bottom","1px solid #000");
}*/

///////////////////////////
//
// INBOX
//
///////////////////////////

/*Header.initialize_inbox = function(){
  $(".show_inbox").live('click', function(e){
    var button = $(this);
    var infos = $("#inbox_infos");
    var option_count = infos.find(".inbox_line").length;
    //if (option_count <= 1) return;//if only one option then don't display options, just follow link
    e.preventDefault();
    e.stopPropagation();
    infos.toggle().css({
      left: button.offset().left - 19
    });
    if (infos.is(':visible'))
      $(document).bind('click',Header.close_inbox_infos);
    else
      $(document).unbind('click',Header.close_inbox_infos);
  });
}

Header.close_inbox_infos = function(){
  var infos = $("#inbox_infos");
  infos.hide();
  $(document).unbind('click',Header.close_inbox_infos);
}


Header.update_ajax = function(){
  $.get("/api/partial/header", function(data){
    var header = $(data);
    $("#inbox_infos").html(header.find("#inbox_infos").html());
    $("#idx_3_top .show_basket .todo").html(header.find(".show_basket .todo").html());
    $("#idx_3_top .show_basket").attr('style', header.find(".show_basket").attr('style'));
    $("#idx_3_top .show_inbox .todo").html(header.find(".show_inbox .todo").html());
    $("#idx_3_top .show_inbox").attr('style', header.find(".show_inbox").attr('style'));
  });
}*/

///////////////////////////
//
// ACTIVITY FEED
//
///////////////////////////

$(function(){

  try {
    //pre-set the computer if a cookie is set
    var ARRcookies=document.cookie.split(";");
    for (var i=0;i<ARRcookies.length;i++)
    {
      var key=ARRcookies[i].substr(0,ARRcookies[i].indexOf("="));
      var val=ARRcookies[i].substr(ARRcookies[i].indexOf("=")+1);
      key=key.replace(/^\s+|\s+$/g,"");
      if (key=="activityfeed_masked" && val=="true")
        $("#activity_feed").addClass('masked');
    }
  } catch (err) {}

  if ($("#activity_feed").length>0) {
    resize_activity_feed();
    $(window).bind('resize', resize_activity_feed);
  }

  //Closing the feed
  /*$(".feed_tool_close").live('click', function(){
    $("#activity_feed").toggleClass('masked');
    document.cookie = "activityfeed_masked="+$("#activity_feed").hasClass('masked')+";path=/";
    resize_activity_feed(true);
  });*/

  $(".feed_tool_config").live('click', function(ev) {
    ev.preventDefault();
    if ( $(".feed_config").is(":visible") ) {

      $(".feed_config").hide();
      $(".feed_config").removeClass('selected');
      $(".feed_tool_config").removeClass('selected');
      $(".notif_head").show();
      $(".feed_content").show();
      $(".feed_content").addClass('selected');

      //reload the activity if something changed
      if ($(".feed_config").hasClass("hasChanged")) {
        $("#activity_feed").html("<div class='feed_content' style='display: table; width:100%; height: 100%;'><div style='display: table-cell;text-align:center;vertical-align: middle;'><img src='/img/transparent_loader_3.gif' style='opacity: 0.4;'/></div></div>");
        $(".feed_config").removeClass("hasChanged")
        $.get("/"+G_user_api.vanity_url+"/feed", function(data) {
         $("#activity_feed").replaceWith(data);
         resize_activity_feed();
        });
      }

    } else {
      $(".feed_config").show();
      $(".feed_config").addClass('selected');
      $(".feed_tool_config").addClass('selected');
      $(".notif_head").hide();
      $(".feed_content").hide();
      $(".feed_content").removeClass('selected');
   }
  });

  $(".feed_config .follow_link").live('click', function(){
    $(".feed_config").addClass("hasChanged");
  });

  $('.feed_abstract_dismiss').live('click', function(){
    var cross = $(this);
    var element = $(this).closest('.feed_item');
    if (cross.html() == "P") return;
    cross.html("P");
    var data_to_send =  {
      'id': cross.attr('data-db-notif_id'),
      'dismiss': true
    };
    $.ajax({
      url:'/api/V2/notif/',
      data: {
        'arg': JSON.stringify(data_to_send),
        'authenticity_token': auth_token
      },
      success: function(data){
        if (data.success)
          element.detach();
        else
          cross.html("'");
        if ($(".notif_content .feed_item").length == 0)
          $(".notif_head").hide();
      },
      error: function(){
        cross.html("'");
      }
    });
  });

  if ($("#activity_feed").length>0) {
    resize_activity_feed();
    $(window).bind('resize', resize_activity_feed);
  }

  if ($("#activity_feed").length>0) {
    $(".feed_item").live('mouseenter', function(){
      try {
        var popup = $(this).find('.feed_popup');
          popup.css('top', '');
          popup.find('.feed_popup_arrow').css('top',  '' );
        if (popup.offset().top + popup.height() > $(window).height() + $(window).scrollTop()  ) {
          var offset = $(window).height() + $(window).scrollTop() - popup.offset().top - popup.height();
          popup.css('top', offset);
          popup.find('.feed_popup_arrow').css('top',  '' );
          popup.find('.feed_popup_arrow').css('top',  parseInt(popup.find('.feed_popup_arrow').css('top')) - offset );
        }
      } catch(e){}
    });
  }

  $(".feed_content").live('click', function(){
    //tracking event for google
    try {
      ga('send', {
        'hitType': 'event',          // Required.
        'eventCategory': 'interaction',   // Required.
        'eventAction': 'activityfeed_click',      // Required.
        'nonInteraction': false
      });
    }catch(e){
      console.log(e);
    }
  });

  $(".feed_content").live('mousewheel', function(event, delta) {
    event.preventDefault();
    var panel = $(this);

    var speed = 10;
    var new_top = parseInt(panel.css('top')) + delta * speed;
    if (isNaN(new_top)) new_top = delta * speed;
    new_top = Math.floor(new_top)
    panel.css('top', new_top);

    var overflow = $("#activity_feed").offset().top+$("#activity_feed").height() - $(".feed_content").offset().top-$(".feed_content").height();
    if (overflow > 0)
      new_top += overflow;
    if (new_top > 0)
      new_top = 0;

    panel.css('top', new_top);
  });

});

function resize_activity_feed(animate) {
  try {
    if (typeof animate != 'boolean') animate = false;

    var feed_size = 210;
    var available = $(window).width() - $("#container").width();

    if (available < 210 || $(window).height() < 200) {
      $("#activity_feed").addClass('hidden');
    } else {
      $("#activity_feed").removeClass('hidden');
    }

    var top_limit = 49;
    var bottom_limit = $(window).height();

    if (animate) {
      $("#activity_feed").animate({ 'top': top_limit, 'width': feed_size, 'height': bottom_limit-top_limit });
    } else {
      $("#activity_feed").css({ 'top': top_limit, 'width': feed_size, 'height': bottom_limit-top_limit });
    }
  } catch(e) {
    $("#activity_feed").addClass('hidden');
  }
}

function initialize_follow_links() {
  var local_is_follow_user_link_active = true;
  $(".follow_link").die('click');

  $(".follow_link").live('click', function(ev){
    if (ev) ev.preventDefault();
    if (!local_is_follow_user_link_active) return;
    local_is_follow_user_link_active = false;
    var target = this;

    var request = {};
    request[ $(target).attr('data-db-follow-what') ] = $(target).attr('data-db-follow-id');
    if ($(target).find(".text_follow:visible").length > 0)
      request['do'] = 'add';
    else
      request['do'] = 'remove';

    $(target).css({'cursor': 'default', 'opacity': 0.5});
    if (request['do'] == 'remove') {
      $(target).find('.text_nohover').css('display', 'none');
      $(target).find('.text_hover').css('display','inline');
    }
    $.ajax({
      url: '/api/user/following',
      datatype: 'json',
      data: request,
      type: 'POST',
      success: function(data){
        if (data.success) {
          //We need to update every follow button for this topic on the page
          $(".follow_link").each(function(i,e){
            var ee = $(e);
            if (ee.attr('data-db-follow-what') == $(target).attr('data-db-follow-what') && ee.attr('data-db-follow-id') == $(target).attr('data-db-follow-id')) {
              if (request['do'] == 'add') {
                ee.find('.text_follow').css('display', 'none');
                ee.find('.text_unfollow').css('display', 'inline');
              } else {
                ee.find('.text_follow').css('display', 'inline');
                ee.find('.text_unfollow').css('display', 'none');
              }
            }
            ee.find('.text_nohover').css('display', '');
            ee.find('.text_hover').css('display', '');
          });
        }
        $(target).css({'cursor': '', 'opacity': ''});
        local_is_follow_user_link_active = true;
      },
      error: function(){
        $(target).find('.text_nohover').css('display', '');
        $(target).find('.text_hover').css('display', '');
        $(target).css({'cursor': '', 'opacity': ''});
        local_is_follow_user_link_active = true;
      }
    });
  });
}



///////////////////////////
//
// SUDO
//
///////////////////////////

function initialize_sudo(){
  $(".make_sudo_link").live('click', function(e){
    e.preventDefault();
    sudo_display_dialog();
  });
  $('#dialog-sudo .user_choice').live('click', function(e){
    e.preventDefault();
    var new_id = $(this).find('.user_choice_id').val();
    var goto_url = $(this).find('.user_choice_url').text();
    if (parseInt(new_id) != new_id) return;
    try {
      if (typeof(diveboard.mask_file) == 'function') diveboard.mask_file(true);
      //$(".user_choice").removeClass('active');
      //$(this).addClass('active');
      $("#dialog-sudo").dialog( "close" );
      window.location.href = goto_url;
    } catch(e){
      if (console && console.log)
        console.log(e)
    }
  });
  if ($("#user_choice_admin .user_choice_id").length > 0){
    $("#user_choice_admin_reset").live('click', function(){
      if (typeof(diveboard.mask_file) == 'function') diveboard.mask_file(true);
      sudo_reset_user();
      $("#dialog-sudo").dialog( "close" );
      window.location = "/"
    });
    $("#user_choice_admin .user_choice_id").autocomplete({
      source: function(request, response){
        $.ajax({
          url:"/api/search/user.json",
          data:({
            q: request.term
          }),
          dataType: "json",
          success: function(data){
            console.log ("plop");
            if (parseInt(request.term) == request.term)
              data.push({
                label: "User with ID "+request.term,
                db_id: request.term,
                value: "User with ID "+request.term,
                picture: null
              });
            response( $.map( data, function( item ) {
              return {
                label: ""+item.db_id+". "+item.label,
                //label: item.label,
                value: item.value,
                db_id: item.db_id,
                picture: item.picture
              }
            }));
          },
          error: function(data) { diveboard.alert(I18n.t(["js","global","A technical error happened while trying to connect to Facebook."])); }
        });
      },
      minLength: 2,autoFocus: true,
      select: function(event, ui){
        sudo_set_user(ui.item.db_id);
        diveboard.mask_file(true);
        $("#dialog-sudo").dialog( "close" );
        window.location.href = window.location.href;
        window.location.reload(true);
      },
      close: function(event, ui){$("#buddy-db-name").val("");}
    });
  }
}

function sudo_display_dialog(){
  if ($("#dialog-sudo").length > 0)
    $("#dialog-sudo").dialog({
      resizable: false,
      modal: true,
      width: '600px',
      zIndex: 99999,
      close: function(){
        if (typeof callback == 'function') callback.apply(this, []);
      },
      buttons: {
        "Cancel": function() {
          $( this ).dialog( "close" );
        }
      }
    });
}

function sudo_set_user(id){
  var domain = $("meta[name='db-cookie-domain']").attr("content");
  document.cookie = "sudo="+id+";path=/;domain="+domain;
}

function sudo_reset_user(){
  var domain = $("meta[name='db-cookie-domain']").attr("content");
  document.cookie = "sudo=;path=/;domain="+domain;
}

////////////////////////////////////
//
// JQuery hooks for dropdowns
//
////////////////////////////////////

function initialize_load_callbacks(){
  initialize_load_callbacks.callbacks = [];

  //Override the load() function, to add global callbacks
  var oldLoad = $.fn.load;
  $.fn.load = function(url, params, callback) {
    var overloaded_callback = function(){
      if (typeof callback === "function") callback.apply(this, arguments);
      else if (typeof params === "function") params.apply(this, arguments);

      for (var i in initialize_load_callbacks.callbacks){
        var callback = initialize_load_callbacks.callbacks[i];
        if (typeof callback === "function") callback.apply(this, arguments);
      }
    };

    if ( typeof url === "string" && typeof params==='function') oldLoad.apply(this, [url, overloaded_callback])
    else if ( typeof url === "string" && typeof callbacks==='function') oldLoad.apply(this, [url, params, overloaded_callback])
    else oldLoad.apply(this, arguments);
  }

}

function add_load_callback(callback){
  if (!initialize_load_callbacks.callbacks)
    initialize_load_callbacks();
  initialize_load_callbacks.callbacks.push(callback);
}

////////////////////////////////////
//
// DISPLAY DATES IN LOCAL TIMEZONE
//
////////////////////////////////////

function initialize_local_timezones(){
  //FOR I18N: Date.locale = 'fr'
  $(".local_timezone").not('.translated').each(function(i,e){
    try {
      var placeholder = $(e);
      var initial_date = placeholder.text();
      var parts = initial_date.match(/([0-9]*)-([0-9]*)-([0-9]*) ([0-9]*):([0-9]*):([0-9]*) UTC/);
      if (!parts) return;
      var date = new Date(Date.UTC(parts[1],parts[2]-1,parts[3],parts[4],parts[5],parts[6]));
      var format = placeholder.data("format");
      if (typeof format === 'undefined')
        format = "%Y-%m-%d %H:%M <span class='timezone'>%Z</span>";
      var new_date = date.strftime(format);
      if (new_date.match(/NaN/)) return;
      placeholder.html(new_date);
      placeholder.addClass('translated');
      placeholder.attr("data-initial_text", initial_date);
    }catch(e){}
  });

  add_load_callback(initialize_local_timezones);
}


////////////////////////////////////
//
// CUSTOM DROPDOWN DESIGN
//
////////////////////////////////////

// This function uses the add_load_callback feature so that once loaded, it should
// not be needed to relaunch it ever again for newly created dropdowns.
function initialize_dropdowns(){
  if (!initialize_dropdowns.initialized) {
    initialize_dropdowns.initialized = true;

    //Override the val() function
    var oldVal = $.fn.val;
    $.fn.val = function() {
      var custom = $(this).data("val");
      return (typeof custom == "function") ? custom.apply(this,arguments) : oldVal.apply(this,arguments);
    };

    //Initialize new dropdowns after each .load()
    add_load_callback(initialize_dropdowns);
  }

  $(".dropdown").not(".initialized").each(function(i,e){
    var dropdown = $(this);

    var button_class = 'grey_button';
    if (dropdown.hasClass('white')) {
      button_class = "white_button"
    } else if (dropdown.hasClass('yellow')) {
      button_class = "yellow_button"
    }

    //Construct the button
    var button = $("<button class='"+button_class+"'><span/><div class='selector'></div></button>");
    button.prependTo(dropdown);

    if (dropdown.attr('name')) {
      $("<input class='dropdown_input_proxy' type='hidden'/>").attr('name', dropdown.attr('name')).prependTo(dropdown);
    }


    //Put some default value
    var options = dropdown.find(".option");
    var selected_val = dropdown.data('selected');
    var found = false;
    if (typeof selected_val == 'undefined') {
      //If value is undefined, let's take the first
      button.find("span")[0].innerHTML = options[0].innerHTML;
      var val = $(options[0]).data('value');
      if (typeof val === 'undefined') val = options[0].innerHTML;
      dropdown.data('selected', val);
      dropdown.find('.dropdown_input_proxy').val(val);
    } else {
      for (var i in options) {
        var option = $(options[i]);
        if (selected_val == option.data('value')) {
          button.find("span")[0].innerHTML = options[i].innerHTML;
          dropdown.find('.dropdown_input_proxy').val(selected_val);
          break;
        }
      }
    }

    //Override the val() of the dropdown
    dropdown.data('val', function(v){
      if (typeof v !== 'undefined'){
        var selected = $(this).find(".option").first();
        $(this).find(".option").each(function(i,e){
          var lv = $(e).data('value');
          if (lv && lv == v)
            selected = $(e);
          else if (typeof lv =='undefined' && $(e).text() == v)
            selected = $(e);
        });
        if (selected)
          selected.click();
      }
      return $(this).data('selected');
    });

    //Initialize bindings
    dropdown.find("button").click(function(ev){
      ev.preventDefault();
      var dropdown = $(this).closest('.dropdown');
      dropdown.toggleClass('active');
      dropdown.find('.options').css('min-width', dropdown.width()-2);
      if (dropdown.hasClass('active')) {
        var close = function(ev2){
          if (ev2.originalEvent != ev.originalEvent) {
            dropdown.removeClass('active');
            $(document).unbind('click',close);
          }
        };
        $(document).bind('click',close);
      }
    });

    dropdown.find(".option").click(function(ev){
      var dropdown = $(this).closest('.dropdown');
      dropdown.removeClass('active');
      var previous_val = dropdown.data('selected');
      var new_val = $(this).data('value');
      var new_html = this.innerHTML;
      //If there is an input field in the option, then let's take its value instead
      if ($(this).find('input').length>0) {
        new_val = $(this).find('input').val();
        if (new_val == "") return;
        new_html = new_val;
        $(this).find('input').val("");
      }
      //Defaults to innerHTML
      if (typeof new_val === 'undefined')
        new_val = new_html;
      //If anything changed at all....
      if (previous_val != new_val) {
        dropdown.data('selected', new_val);
        dropdown.find('.dropdown_input_proxy').val(new_val);
        dropdown.find("button span")[0].innerHTML = new_html;
        dropdown.trigger('change');
      }
    });

    dropdown.find(".option input").click(function(ev){
      ev.stopPropagation();
    });

    dropdown.find(".option input").bind('keypress', function(ev){
      if (ev.charCode==13) $(this).closest(".option").trigger('click');
    });


    //OK everything is fine
    dropdown.addClass('initialized');
  });


}

////////////////////////////////////
//
// EMBEDDED IMAGE MANIPULATION
//
////////////////////////////////////




diveboard.resizer = function() {
  if (!diveboard.resizer.support ())
    return;
  this.img = new Image();
  this.canvas = document.createElement("canvas");
  this.queue = [];
}

diveboard.resizer.support = function() {
  if (typeof diveboard.resizer.support.cache == 'undefined') {
    if (((window.webkitURL && window.webkitURL.createObjectURL) || (window.URL && window.URL.createObjectURL)) && document.createElement("canvas").getContext)
      diveboard.resizer.support.cache = true
    else
      diveboard.resizer.support.cache = false
  }

  return diveboard.resizer.support.cache
}

diveboard.resizer.prototype = {
  queue: null,
  used: false,
  img: null,
  canvas: null,

  // Options should include :
  // Mandatory
  //   - file
  // Callbacks :
  //   - start, end, error, cancel
  // For resizing :
  //   - max_width, max_height,
  // For cropping :
  //   - x0, y0, x1, y1
  resize_picture: function(options) {
    if (this.used){
      this.queue.push({t:this, args:arguments});
      return;
    }
    this.used = true;
    var file = options.file;
    var max_height = options.max_height;
    var max_width = options.max_width;
    var x0 = options.x0;
    var y0 = options.y0;
    var x1 = options.x1;
    var y1 = options.y1;
    var callback_start = options.start;
    var callback_end = options.end;
    var callback_error = options.error;
    var callback_cancel = options.cancel;


    if (window.webkitURL && window.webkitURL.createObjectURL)
      this.img.src = window.webkitURL.createObjectURL(file);
    else if (window.URL && window.URL.createObjectURL)
      this.img.src = window.URL.createObjectURL(file);
    else
      throw "createObjectURL not supported"

    var resizer = this;

    this.img.onerror = function(e) {

      if (callback_error)
        callback_error.apply(resizer, [e]);

      if (window.webkitURL && window.webkitURL.revokeObjectURL)
        window.webkitURL.revokeObjectURL(resizer.img.src);
      else if (window.URL && window.URL.revokeObjectURL)
        window.URL.revokeObjectURL(resizer.img.src);

      resizer.img.onload = function(){};
      resizer.img.onerror = function(){};
      resizer.img.src=null;
      resizer.used = false;

      if (resizer.queue.length > 0){
        var req = resizer.queue.shift();
        diveboard.resizer.prototype.resize_picture.apply(req.t, req.args)
      }
    }

    this.img.oncancel = function(){
      if (callback_cancel)
        callback_cancel.apply(resizer, []);
    }

    this.img.onload = function(e){
      // resize.
      try {
        var ctx = resizer.canvas.getContext('2d');

        if (!x0 || !x1 || !y0 || !y1){
          x0 = 0;
          y0 = 0;
          x1 = resizer.img.width;
          y1 = resizer.img.height;
        }

        var width = x1-x0;
        var height = y1-y0;

        if (max_width && max_height) {
          if ( Math.max(width,height) > max_width || Math.min(width,height) > max_height   )
            if (width>height)
              if (width/max_width > height/max_height)  {
                height = Math.round(height*max_width/width);
                width = max_width
              } else {
                width = Math.round(width*max_height/height);
                height = max_height
              }
            else {
              if (height/max_width > width/max_height)  {
                width = Math.round(width*max_width/height);
                height = max_width
              } else {
                height = Math.round(height*max_height/width);
                width = max_height
              }
            }
        }
        resizer.canvas.width = width;
        resizer.canvas.height = height;
        ctx.drawImage(resizer.img, x0, y0, x1-x0, y1-y0, 0, 0, resizer.canvas.width, resizer.canvas.height);

        if (callback_end)
          callback_end.apply(resizer.canvas, [resizer.canvas.toDataURL("image/jpeg")]);
      } catch(e){
        if (callback_error)
          callback_error.apply(resizer, [e]);
      }

      if (window.webkitURL && window.webkitURL.revokeObjectURL)
        window.webkitURL.revokeObjectURL(resizer.img.src);
      else if (window.URL && window.URL.revokeObjectURL)
        window.URL.revokeObjectURL(resizer.img.src);

      resizer.img.onload = function(){};
      resizer.img.onerror = function(){};
      resizer.img.src=null;
      resizer.used = false;

      if (resizer.queue.length > 0){
        var req = resizer.queue.shift();
        diveboard.resizer.prototype.resize_picture.apply(req.t, req.args)
      }
    }

    if (callback_start)
      callback_start(file);
  },

  cancel: function() {
    var resizer = this;
    $.each(this.queue, function(i,element){
      //call callback_cancel
      if (element.args[6])
        element.args[6].apply(resizer, []);
    });
    this.queue = [];
    this.img.onload = function(){
      if (window.webkitURL && window.webkitURL.revokeObjectURL)
        window.webkitURL.revokeObjectURL(resizer.img.src);
      else if (window.URL && window.URL.revokeObjectURL)
        window.URL.revokeObjectURL(resizer.img.src);
      resizer.used = false;
      resizer.img.src = null;
    };
  }

}

diveboard.setup_crop_upload = function(options){
  var im;
  var crop_pictname;
  var original_url;
  var parent_selector = options.selector;
  var preview_callback = options.preview || function(){};
  var cancel_callback = options.cancel;
  var confirm_callback = options.confirm;
  var box_width = options.box_width || 400;
  var aspect_ratio = 1;
  if (typeof options.aspect_ratio != "undefined")
    aspect_ratio = options.aspect_ratio;
  var full_selected = options.full_selected || false;
  var allow_images = options.allow_images || true;
  var allow_videos = options.allow_videos || false;
  var allow_docs = options.allow_docs || false;

  var allowed_extensions = [];
  if (allow_images)
    Array.prototype.push.apply(allowed_extensions, ['jpg', 'jpeg', 'png', 'gif', 'tiff', 'tif', 'bmp', 'tga', 'xcf', 'psd', 'ai','svg', 'pcx']);
  if (allow_videos)
    Array.prototype.push.apply(allowed_extensions, ['mpeg', 'avi', 'mov', 'webm', 'ogv', 'mp4', 'wmv', 'flv']);
  if (allow_docs)
    Array.prototype.push.apply(allowed_extensions, ['pdf']);

  var api = {
    getImage: function(){return im;},
    getPictname: function(){return crop_pictname},
    getOriginal: function(){return original_url},
    reset: function(){
      try {$(parent_selector+" .qq-upload-success").html('');} catch(e){}
      $(parent_selector+" .imageuploader").show();
      $(parent_selector+" .picture_table").hide();
    },
    tellSelect: function(){ return $(parent_selector+" .pictureimg").data('Jcrop').tellSelect(); }
  };

  $(parent_selector+" .image_cancel").bind('click', function(){
    try {$(parent_selector+" .qq-upload-success").html('');} catch(e){}
    $(parent_selector+" .imageuploader").show();
    $(parent_selector+" .picture_table").hide();
    if (cancel_callback)
      cancel_callback(api);
  });

  if (confirm_callback)
    $(parent_selector+" .image_confirm").bind('click', function(){
      confirm_callback(api);
    });
  else
    $(parent_selector+" .image_confirm").detach();

  new qq.FileUploader({
      // pass the dom node (ex. $(selector)[0] for jQuery users)
      element: $(parent_selector+" .select_file_btn")[0],
      // path to server-side upload script
      action: '/settings/uploadpict',
    // additional data to send, name-value pairs
    params: {
      user_id: options.user_id,
      'authenticity_token': auth_token
    },
    // validation
    allowedExtensions: allowed_extensions,
    sizeLimit: 20971520, // max size in byte
    //minSizeLimit: 0, // min size

    // set to true to output server response to console
    debug: false,
    multiple: false,


    // events
    // you can return false to abort submit
    onSubmit: function(id, fileName){
      //clean-up the mess....
      $(parent_selector+" .qq-upload-list").empty();
    },
    onProgress: function(id, fileName, loaded, total){},
    onComplete: function(id, fileName, responseJSON){
      if (responseJSON["success"] == "false" || responseJSON["success"] == undefined) {
        $(parent_selector+" .qq-upload-failed-text").show();
      }else{
        if(options.crop && responseJSON["cropable"]){
          var filename = responseJSON["filename"];
          $(parent_selector+" .upload_progress").hide();
          if(filename == "" || filename == null){
            //uplod actually failed
            $(parent_selector+" .qq-upload-file").hide();
            $(parent_selector+" .qq-upload-size").hide();
            $(parent_selector+" .qq-upload-failed-text").show();
            return;
          }
          crop_pictname = filename;
          original_url = responseJSON["tempfullpermalink"];
          // WARNING => DO NOOOOOT CHANGE THE ORDER OF THE LOADING , it will fail....
          im =$('<img class="pictureimg" />');
          im.bind("load",function(){
            //alert("picture has been loaded fully");
            //strip the pict so it shows up
            //if ( $("#picturepreview").find("img")[0].width > 450)  $($("#picturepreview").find("img")[0]).width(450)
            $(parent_selector+" .imageuploader").hide();
            $(parent_selector+" .picture_table").show();

            var sel_size_w = im[0].width || 100;
            var sel_size_h = im[0].height || 100;
            if (aspect_ratio) {
              if (sel_size_w/aspect_ratio > sel_size_h)
                sel_size_w = sel_size_h * aspect_ratio;
              else if (sel_size_h*aspect_ratio > sel_size_w)
                sel_size_h = sel_size_w / aspect_ratio;
            }

            $(parent_selector+" .pictureimg").Jcrop({
                onChange: preview_callback,
                onSelect: preview_callback,
                boxWidth: box_width,
                setSelect:   [ 0, 0, sel_size_w, sel_size_h ],
                aspectRatio: aspect_ratio
              });
            selected_pic = 1;
          });
          $(parent_selector+" .picturepreview").empty();
          $(parent_selector+" .picturepreview").append(im);
          im.attr("src", "/tmp_upload/"+crop_pictname);
          $(parent_selector+" .preview").attr("src", "/tmp_upload/"+crop_pictname);
          $(parent_selector+" .qq-upload-list").empty();
        }else{
          var filename = responseJSON["filename"];
          var tempfullpermalink = responseJSON["tempfullpermalink"];
          confirm_callback({
            reset: function(){},
            tellSelect: function(){return null},
            getPictname: function(){return filename},
            getOriginal: function(){return tempfullpermalink}
          });
          $(parent_selector+" .qq-upload-list").empty();
        }
      }
    },
    onCancel: function(id, fileName){},

    messages: {
        // error messages, see qq.FileUploaderBasic for content
      typeError: I18n.t(["js","global","{file} has invalid extension. Only {extensions} are allowed."]),
                sizeError: I18n.t(["js","global","{file} is too large, maximum file size is {sizeLimit}."]),
                minSizeError: I18n.t(["js","global","{file} is too small, minimum file size is {minSizeLimit}."]),
                emptyError: I18n.t(["js","global","{file} is empty, please select files again without it."]),
                onLeave: I18n.t(["js","global","The files are being uploaded, if you leave now the upload will be cancelled."])
    },
    showMessage: function(message){ alert(message); }
  });

  return api;
}

diveboard.remove_crop_upload = function(parent_selector){
  if(qq)
    qq.remove($(parent_selector+" .select_file_btn")[0]);
}

diveboard.user_pictures_picker = function(user_id, callback){
  user_pictures = [];
  diveboard.mask_file(true, {"z-index": 900000});

  var buttons = {}
  buttons["Cancel"] = function(){return;}
  var current_page = 0;
  var page_size = 50;
  var generate_pictures_list = function (data, page){
    var result="";
    var max_pages = Math.floor(data.length / page_size);
    if ((data.length / page_size)-max_pages > 0)
      max_pages++;

    for(var i = page_size*page; i < page_size*(page+1); i++){
        try{
         result+="<div class='box'><img src='"+data[i].small+"' data='"+data[i].full_redirect_link+"'onerror='detach_from_masonry(this);' style='width: 100px; display: inline-block;'/></div>";
        }catch(e){}
      }
      if(page==max_pages){
        $(".pictures_picker_list .yellow_button").hide();
      }
      return result;
  }

  var load_next_images = function(){
    current_page++;
    $('.pictures_picker_list .masonry_container .yellow_button span').show();
    $('.pictures_picker_list .masonry_container').append(generate_pictures_list(user_pictures, current_page));
    var container = $('.pictures_picker_list .masonry_container');
    container.imagesLoaded(function(){
      $('.pictures_picker_list .masonry_container').masonry('appended', $('.pictures_picker_list .masonry_container .box:not(.masonry-brick)'), true);
      $('.pictures_picker_list .masonry_container .yellow_button span').hide();
    });
  }

  setTimeout(function(){
    $.ajax({
      type: 'GET',
      dataType: 'json',
      url: "/api/V2/user/"+user_id,
      data:{
        flavour: 'pictures'
      },
      error: function(jqXHR, textStatus, errorThrown){
        hide_loader();
        alert("Could not load your dives - Check your internet connection");
        console.log(textStatus+" "+errorThrown);
        build_dives_list_fail();
        refresh_scroller("dive_list");
      },
      success: function(data){
        diveboard.unmask_file();
        user_pictures = data.result.own_pictures;
        diveboard.propose(I18n.t(["js","global","Pick a picture from your gallery"]),'<p class="dialog-text-highlight">'+I18n.t(["js","global","Scroll down to load more"])+'</p><div class="pictures_picker_list" style="width: 100%;"></div>', buttons);
          $("#dialog-global-notify").parent().css({width: "80%", height: "80%", left: "10%", top: "10%"});
          $('.pictures_picker_list').css("height",($('.pictures_picker_list').closest(".ui-dialog").height()-150)+"px");
          $('.pictures_picker_list').append("<div class='masonry_container'>");
          $('.pictures_picker_list .masonry_container').append(generate_pictures_list(user_pictures, 0));
          $('.pictures_picker_list').append('<center><div class="yellow_button" style="width: 90%; text-align: center; ">Load 50 next pics<span style="margin-left: 10px;top: 2px;position: relative; display:none;"><img src="/img/loading.gif"></span></div></center>');
          $('.pictures_picker_list .yellow_button').click(load_next_images);
          $('.pictures_picker_list .masonry_container .box').on("click", function(e){
            coco = e;
            console.log("callback with "+$(e.target).attr("data"));
            callback($(e.target).attr("src"), $(e.target).attr("data"));
            $(e.currentTarget).closest(".ui-dialog").remove();
            diveboard.unlock_scroll();
          });
        var container = $('.pictures_picker_list .masonry_container');
          container.imagesLoaded(function(){
            container.masonry({
              itemSelector: '.box',
              isAnimated: false,
              isFitWidth: false,
              columnWidth: 15
            });
          });
      }
    });
  }, 50);


}

diveboard.lock_scroll_force = function(ev,x,y){
  if(ev)
    ev.preventDefault();
  window.scrollTo(x,y);
}

diveboard.lock_scroll = function (x,y){
  // lock scroll position, but retain settings for later
  var scrollPosition = [
    self.pageXOffset || document.documentElement.scrollLeft || document.body.scrollLeft,
    self.pageYOffset || document.documentElement.scrollTop  || document.body.scrollTop
  ];
  if (typeof(x) == "undefined")
    var x=self.pageXOffset;
  if (typeof(y) == "undefined")
    var y=self.pageYOffset;

  var html = jQuery('html'); // it would make more sense to apply this to body, but IE7 won't have that
  html.data('scroll-position', scrollPosition);
  html.data('previous-overflow', html.css('overflow'));
  html.css('overflow', 'hidden');
  window.scrollTo(x, y);
  $(window).scroll(function(ev){ diveboard.lock_scroll_force(ev,x,y);});
}




diveboard.unlock_scroll = function(){
  // un-lock scroll position
  var html = jQuery('html');
  var scrollPosition = html.data('scroll-position');
  html.css('overflow', html.data('previous-overflow'));
  $(window).unbind('scroll');
  window.scrollTo(scrollPosition[0], scrollPosition[1]);

}

diveboard.request_sign_in = function(){
  var buttons = {};
  buttons["Cancel"] = function(){
    diveboard.mask_file(true);
    history.back();
  }
  $("#login_popup").attr("id", "login_popup_old");

  diveboard.propose(I18n.t(["js","global","Sign-in required"]),I18n.t(["js","global","You need to sign in to continue"])+"<br/><div style='height: 285px;'>"+$("#inline_popup_text_template").html().toString()+"</div>", buttons);

}


diveboard.extract_changed_data = function(initial_data, changed_data){
  //will remove from changed data all attributes that are === in initial_data
  var new_data = {};
  $.each(changed_data, function(idx, el){
    if(initial_data[idx] != el)
      new_data[idx] = el;
  })
  return new_data;
}


diveboard.show_sign_up_popup = function(){
  window.scrollTo(0, 0);
  diveboard.lock_scroll();
}

diveboard.require = function(url, callback){
  if (url == 'plusone') url = "https://apis.google.com/js/plusone.js";
  if (typeof diveboard.required == 'undefined') diveboard.required = {};
  if (diveboard.required[url])
    callback();
  else
    $.ajax({
      type: "GET",
      url: url,
      success: callback,
      dataType: "script",
      cache: true
    });
}

diveboard.plusone_go = function(){
  window.___gcfg = {
    parsetags: 'explicit'
  };
  diveboard.require('plusone', function(){
    try {
      gapi.plusone.go();
    } catch(e) {
        var objHTML = $("#pluginContainer").html();
        $("#pluginContainer").html("");
        try {
          gapi.plusone.go();
        } catch(f) {}
        $("#pluginContainer").html(objHTML);
    }
  });
}


///////////////////////////
//
// Facebook get permissions
//
///////////////////////////

diveboard.check_or_add_fb_permission = function(permission_list, callback_success, callback_fail, force) {
  //permission list must be a CSV list
  var fb_response;

  var show_relog_popup = function(){
    var buttons = {};
    buttons[I18n.t(["js","global","Cancel"])] = function(){
      diveboard.unmask_file();
      callback_fail();
    }
    buttons[I18n.t(["js","global","Authorize Facebook"])] = function(){
      force_relog();
    }

    diveboard.propose(I18n.t(["js","global","Missing permissions"]), I18n.t(["js","global","You need to authorize the Diveboard application with additional permissions over your Facebook account to proceed:"])+"<br/>"+permission_list, buttons);
  }

  var check_permissions = function(cb_success, cb_fail){
    FB.api('/v2.0/me/permissions', function (response) {
      var all_perms = true;
      var missing_perms = [];
      $.each(permission_list.split(","), function(idx, el){
        if (response.data[0][el] != 1){
          all_perms = false;
          missing_perms.push(el);
        }
      });
      if (all_perms){
        //console.log("perms OK");
        cb_success();
      }else{
        //console.log("perms KO");
        cb_fail(missing_perms);
      }
    });
  }

  var update_fbtoken = function(){
    //console.log("updating fbtoken on DB");
    $.ajax({
      url: '/api/update_fbtoken',
      dataType: 'json',
      data: {
        fbtoken: fb_response.authResponse.accessToken,
        fbuserid: fb_response.authResponse.userID,
        'authenticity_token': auth_token
      },
      type: "POST",
      success:  function(data){
        if (data.success){
          G_user_fbtoken = fb_response.authResponse.accessToken;
          if(typeof(callback_success) == "function")
            callback_success();
        } else {
          //detail the alert
          diveboard.notify(I18n.t(["js","global","A technical error occured"]), data.error);
          if(typeof(callback_fail) == "function")
            callback_fail();
        }
      },
      error: function(data){
        diveboard.alert(I18n.t(["js","global","A technical error occured"]), data, function(){
          error();
        });
        if(typeof(callback_fail) == "function")
          callback_fail();
      }
     });
  }

  var force_relog = function(){
    //console.log("forcing login");
    FB.login(function(response) {
      fb_response = response;
      if (response.authResponse) {
        //console.log("checking perms");
        check_permissions(
          function(){
            //console.log("perms ok, updating token");
            update_fbtoken();
          },
          function(missing_perms){
            //console.log("bad perms");
            diveboard.notify(I18n.t(["js","global","Unsufficient privileges"]),I18n.t(["js","global","Could not get the adequate Facebook permissions: "])+missing_perms.toString());
            if(typeof(callback_fail) == "function")
              callback_fail();
          });
      }else{
        //console.log("nologin");
        diveboard.notify(I18n.t(["js","global","FB Login cancelled"]),I18n.t(["js","global","Facebook login was cancelled by user"]));
        if(typeof(callback_fail) == "function")
          callback_fail();
      }
    }, {scope: permission_list});
  }


  FB.getLoginStatus(function(response) {
    fb_response = response;
    if (response.status === "connected"){
      //console.log("user already logged");
      check_permissions(function(){
        if(G_user_fbtoken && G_user_fbtoken == fb_response.authResponse.accessToken){
          if(typeof(callback_success) == "function")
            callback_success();
        }else{
          update_fbtoken();
        }
      }, show_relog_popup);
    }else{
      //console.log("user already not logged");
      show_relog_popup();
    }
  });

}


////////////////////////////////////////
//
// BASKET FUNCTIONS
//
////////////////////////////////////////
function initialize_global_basket(){

  $(".shop_checkout_action").live('click', function(e){
    if(e) e.preventDefault();
    $("#dialog_basket").dialog('close');
    if (typeof G_user_api == 'undefined' && $("#login_basket").length > 0) {
      $("#login_basket").dialog({
        resizable: false,
        modal: true,
        width: '700px',
        zIndex: 99999,
        buttons: {},
        close: function(){
          diveboard.unmask_file();
          $(this).dialog('destroy');
        }
      });
    } else {
      paypal_basket_start($(this).data('basket_id'));
    }
  });


  $(".buy_button").live('click', function(){
    if (diveboard.postpone_me_template(['template_buy_dive', 'template_buy_dive_diver'], this)) return;
    diveboard.mask_file();
    var what = $(this).data('what_to_buy');
    var modify_item = $(this).data('modify_item');
    var shop = $(this).data('shop');

    var long_title = [what.cat1, what.cat2, what.cat3, what.title].filter(function(txt){ return txt && !txt.match(/^[\s]*$/) }).join(" > ");

    //Decide which kind of dialog to display depending on what to buy
    var dedicated_dialog = $("<div class='dialog_buy_class'></div>");
    dedicated_dialog.html(tmpl('template_buy_dive', {shop: shop, what: what, item: modify_item||{details:{}} }));
    dedicated_dialog.data('what_to_buy', what);
    dedicated_dialog.data('shop', shop);
    if (modify_item) dedicated_dialog.data('modify_item', modify_item);
    dedicated_dialog.find('.dup_title').text(what.title)
    $.datepicker.setDefaults($.datepicker.regional[$("html").attr("lang") || 'en']);
    var today = Date.now();
    var min_date = today + Math.ceil(shop.delay_bookings/24+1)*24*3600*1000;
    var max_date = today + 365*24*3600*1000;
    dedicated_dialog.find(".date_picker").datepicker({
      dateFormat: 'yy-mm-dd',
      changeMonth: true,
      changeYear: true,
      minDate: new Date(min_date),
      maxDate: new Date(max_date),
      gotoCurrent: true,
      onClose: function(dateText, inst) {
        if (!dateText.match(/[0-9]{4}-[0-9]{2}-[0-9]{2}/)){
          $("#wizard-date").val("");
        }
      }
    });

    diveboard.unmask_file();
    dedicated_dialog.dialog({
      resizable: false,
      modal: true,
      width: '700px',
      zIndex: 99999,
      title: long_title,
      buttons: {}
    });

    ga('send', 'event', 'shop', 'book_now');
  });


  $(".dialog_buy_class .cancel_button").live('click', function(){
    $(this).closest('.dialog_buy_class').dialog('close');
    diveboard.unmask_file();
  });

  $(".dialog_buy_class .submit_button").live('click', function(){
    var dlg = $(this).closest('.dialog_buy_class');
    var what = dlg.data('what_to_buy');
    var shop = dlg.data('shop');
    var modify_item = dlg.data('modify_item');

    var elt = {
        id: what.id,
        quantity: 0,
        deposit_option: dlg.find('input[name=deposit_option]:checked').val()
    }

    //Counting the total quantity
    dlg.find(".diver_detail").not(".template").find(".quantity").each(function(i,e){
      var x = Number($(e).val());
      if (!isNaN(x))
        elt.quantity += x;
    });

    //Filling up the details
    elt.details = {
      pref_when: dlg.find('.pref_when').val(),
      constraints: dlg.find('.constraints').val(),
      contact: dlg.find('.contact').val(),
      date_type: dlg.find("input[name=date_type]:checked").val()
    };

    //Date details
    if (elt.details.date_type == "period"){
      elt.details.date_from = dlg.find('.date_from').val();
      elt.details.date_to = dlg.find('.date_to').val();
    } else {
      elt.details.date_at = dlg.find('.date_at').val();
    }

    //Diver details
    elt.details.divers = [];
    dlg.find('.diver_detail').not('.template').each(function(i,e){
      var diver = $(e);
      var detail = {};
      detail.certification = diver.find('.certification').val();
      detail.quantity = diver.find('.quantity').val();
      elt.details.divers.push(detail);
    });


    //Let's see if anything is wrong
    if (elt.details.date_type == "period" && (!diveboard.isValidDate(elt.details.date_from) || !diveboard.isValidDate(elt.details.date_to))) {
      diveboard.notify(I18n.t(["js","global","Form validation error"]), I18n.t(["js","global","You must enter valid dates. Please check again the dates you have entered."]));
      return;
    }

    if (elt.details.date_type == "period" && (Date.parse(elt.details.date_from) >= Date.parse(elt.details.date_to ))) {
      diveboard.notify(I18n.t(["js","global","Form validation error"]), I18n.t(["js","global","The date 'From' must be before the date 'Until'."]));
      return;
    }

    if (shop.delay_bookings >= 0 && elt.details.date_type == "period" && (Date.parse(elt.details.date_from) <= Date.now() + (shop.delay_bookings)*3600*1000)) {
      if (shop.delay_bookings == 0 || Date.parse(elt.details.date_from) <= Date.now()-3600*24*1000) diveboard.notify(I18n.t(["js","global","Form validation error"]), "Sorry, bookings cannot be done in the past. Please check the dates.");
      else diveboard.notify(I18n.t(["js","global","Form validation error"]), I18n.t(["js","global","Sorry, bookings must be done %{count} days in advance.<br/><br/>Please change the dates or contact the dive center directly."], {count: Math.ceil(shop.delay_bookings/24+1)}));
      return;
    }

    if (elt.details.date_type != "period" && !diveboard.isValidDate(elt.details.date_at) ) {
      diveboard.notify(I18n.t(["js","global","Form validation error"]), I18n.t(["js","global","You must enter valid dates. Please check again the date you have entered."]));
      return;
    }

    if (shop.delay_bookings >= 0 && elt.details.date_type != "period" && (Date.parse(elt.details.date_at) <= Date.now() + (shop.delay_bookings)*3600*1000)) {
      if (shop.delay_bookings == 0 || Date.parse(elt.details.date_at) <= Date.now()-3600*24*1000) diveboard.notify(I18n.t(["js","global","Form validation error"]), "Sorry, bookings cannot be done in the past. Please check the dates.");
      else diveboard.notify(I18n.t(["js","global","Form validation error"]), I18n.t(["js","global","Sorry, bookings must be done %{count} days in advance.<br/><br/>Please change the dates or contact the dive center directly."], {count: Math.ceil(shop.delay_bookings/24+1)}));
      return;
    }

    if (elt.details.divers.length <= 0) {
      diveboard.notify(I18n.t(["js","global","Form validation error"]), I18n.t(["js","global","Sorry, the number of divers must be a positive integer... Even if you have a lot of buyancy, you cannot count as -1 diver. And your kid should be counted as 1, not 0.57."]));
      return;
    }

    for (var i in elt.details.divers) {
      diver = elt.details.divers[i];
      if (diver.certification.match(/^ *$/)){
        diveboard.notify(I18n.t(["js","global","Form validation error"]), I18n.t(["js","global","Please provide a certification detail for each diver.<br/><br/>To register people who don't dive, just enter 'None' or 'Non diver'."]));
        return;
      }
      if (!diveboard.isNumeric(diver.quantity) || parseInt(diver.quantity) <= 0){
        diveboard.notify(I18n.t(["js","global","Form validation error"]), I18n.t(["js","global","Sorry, amounts must be positive integers... I know it's not imaginative, but it really has to be."]));
        return;
      }
    }

    diveboard.mask_file(true);
    dlg.dialog('close');

    console.log(elt);

    var data_to_send = {
      elt: JSON.stringify(elt),
      'authenticity_token': auth_token
    }

    var url;
    if (modify_item && modify_item.id) {
      url = "/api/basket/update";
      data_to_send.id = modify_item.id;
    } else {
      url = "/api/basket/add";
    }

    //Pushing to basket
    $.ajax({
      url: url,
      type: "POST",
      data: data_to_send,
      success: function(){
        $("#dialog_basket .basket_content").load("/api/basket/view_html", function(){
          $("#dialog_basket").dialog({
            resizable: false,
            modal: true,
            width: '900px',
            zIndex: 99999,
            buttons: {}
          });
          diveboard.unmask_file();
        });
        //Making sure the basket button is displayed
        Header.update_ajax();
      },
      error: function(){
        Header.update_ajax();
      }
    });


  });

  $(".dialog_buy_class input[name=date_type]").live('change', function(){
    var selected = $(this).val();
    var dlg = $(this).closest('.dialog_buy_class');
    dlg.find(".form_date_type").hide();
    dlg.find(".form_date_type_"+selected).show();
  });

  $(".large_click").live('click', function(e){
    $(this).find("input").click();
  });

  $(".large_click input").live('click', function(e){
    e.stopPropagation();
  });

  $(".dialog_buy_class input.date_from, .dialog_buy_class input.date_at").live("change", function(){
    var dlg = $(this).closest('.dialog_buy_class');
    var from_date = $(this).datepicker('getDate');
    var from = dlg.find('input.date_from');
    var to = dlg.find('input.date_to');
    var at = dlg.find('input.date_at');

    if (from_date) {
      var to_date = new Date();
      to_date.setDate(from_date.getDate()+6);
      to.datepicker('setDate', to_date);
      at.datepicker('setDate', from_date);
      from.datepicker('setDate', from_date);
      to.datepicker('option', 'minDate', from_date);
    } else {
      var min_date = from.datepicker('option', 'minDate');
      to.datepicker('option', 'minDate', min_date);
    }
  });

  //number of person changes
  $(".dialog_buy_class .nb_divers_input").live('change', function(){
    var dlg = $(this).closest('.dialog_buy_class');
    var what = dlg.data('what_to_buy');
    var current_lines = dlg.find('.diver_detail').not('.template');
    var new_nb = $(this).val();

    if (new_nb < current_lines.length) {
      current_lines.slice(new_nb).detach();
    }
    else for (var i = 0; i<new_nb-current_lines.length; i++) {
      var num = dlg.find(".diver_detail_list .diver_detail").length+1;
      dlg.find(".diver_detail_list").append(tmpl('template_buy_dive_diver', {quantity: 1, certification: "", 'number': num}));
      dlg.find('.dup_title').text(what.title)
    }
  });


  //Make sure we'll be able to display the basket
  if ($("#dialog_basket").length == 0 ){
    $('body').append("<div id='dialog_basket' style='display:none'><div class='basket_content'></div></div>");
  }

  $(".show_basket").live('click', function(){
    diveboard.mask_file(true);
    $("#dialog_basket .basket_content").load("/api/basket/view_html", function(){
      diveboard.unmask_file();
      $("#dialog_basket").dialog({
        resizable: false,
        modal: true,
        width: '900px',
        zIndex: 99999,
        buttons: {}
      });
    });
  });

  $("#dialog_basket .buy_button").live('click', function(){
    $("#dialog_basket").dialog("close");
  })

  $("#dialog_basket .remove_basket_item").live('click', function(){
    var item_id = $(this).data('item_id');
    var basket = $(this).closest('.basket_content');
    basket.html("<img src='/img/transparent_loader_2.gif'/>");

    $.ajax({
      url: "/api/basket/remove",
      type: "POST",
      data: {
        id: item_id,
        'authenticity_token': auth_token
      },
      success: function(){
        $("#dialog_basket .basket_content").load("/api/basket/view_html");
        Header.update_ajax();
      },
      error: function(){
        $("#dialog_basket .basket_content").load("/api/basket/view_html");
        Header.update_ajax();
      }
    });
  });

  $("#dialog_basket .close_dialog").live('click', function(){
    $("#dialog_basket").dialog("close");
  });
}


function paypal_basket_start(basket_id) {
  diveboard.mask_file(true, {"z-index": 9000});

  $.ajax({
    url: '/api/paypal/start_basket',
    dataType: 'json',
    type: "GET",
    data: {
      basket_id: basket_id
    },
    success: function(data){
      if (data.success) {
        window.location.replace(data.url);
      }
      else {
        diveboard.alert(I18n.t(["js","global","A technical error occured while initialising the payment process with Paypal."]), data);
        diveboard.unmask_file({"background-color": "#000000"});
      }
    },
    error: function(data) {
      diveboard.alert(I18n.t(["js","global","A technical error occured while initialising the payment process with Paypal."]));
      diveboard.unmask_file({"background-color": "#000000"});
    }
  });
}

////////////////////////////////////////////
// SVG icons
////////////////////////////////////////////
function supportsSVG() {
  return !! document.createElementNS && !! document.createElementNS('http://www.w3.org/2000/svg','svg').createSVGRect;
}
function initialize_svg_icons(){
  if (!supportsSVG()) {
    $('img.svg_icon[src*="svg"]').attr('src', function() {
      return $(this).addClass('no_svg_support').attr('src').replace('.svg', '.png');
    });
  } else {
    $('img.svg_icon').each(function(){
        var img = $(this);
        var imgID = img.attr('id');
        var imgClass = img.attr('class');
        var imgURL = img.attr('src');
        var div = $("<div/>");

        div.load(imgURL, function() {
            // Get the SVG tag, ignore the rest
            var svg = div.find('svg');

            // Add replaced image's ID to the new SVG
            if(typeof imgID !== 'undefined') {
                svg = svg.attr('id', imgID);
            }
            // Add replaced image's classes to the new SVG
            if(typeof imgClass !== 'undefined') {
                svg = svg.attr('class', imgClass+' replaced-svg');
            }

            // Remove any invalid XML tags as per http://validator.w3.org
            svg = svg.removeAttr('xmlns:a');

            // Replace image with new SVG
            img.replaceWith(svg);
        });
    });
  }
};


diveboard_ask_for_vote = function() {
  if (location.pathname === '/' || location.pathname === '' ) {
    return;
  }

    var ARRcookies=document.cookie.split(";");
    for (var i=0;i<ARRcookies.length;i++)
    {
      var key=ARRcookies[i].substr(0,ARRcookies[i].indexOf("="));
      var val=ARRcookies[i].substr(ARRcookies[i].indexOf("=")+1);
      key=key.replace(/^\s+|\s+$/g,"");
      if (key=="TC2013_asked")
      {
        //Do not ask if already asked
        return;
      }
    }

  $( "#dialog-global-ask-for-vote" ).dialog({
      resizable: false,
      modal: true,
      width: '600px',
      zIndex: 99999,
      close: function(){
        var exdate=new Date();
        exdate.setDate(exdate.getDate() + 5);
        document.cookie = "TC2013_asked=true;path=/;expires="+exdate.toUTCString()+"domain="+$("meta[name='db-cookie-domain']").attr("content");
      },
      buttons: {}
  });

  $("#dialog-global-ask-for-vote .call_to_action").click(function(ev){
    $("#dialog-global-ask-for-vote").dialog( "close" );
  });
};






////////////////////////////////////////////
// Language selection
////////////////////////////////////////////
function initialize_language_selector(){
  $("#header_container .switch_language").click(function(ev){
    if (ev) ev.preventDefault();
    $("#switch_language_dialog").dialog({
        resizable: false,
        modal: true,
        width: '400px',
        zIndex: 99999,
        buttons: {},
        close: function(){
          diveboard.unmask_file();
        }
      });
  });

  $("#switch_language_dialog .lang").click(function(ev){
    window.location.hostname = $(this).data("href-hostname")
    $("#switch_language_dialog").dialog('close');
    diveboard.mask_file(true);
  })
}


function send_affiliation_code(){
  $("#wrong_affiliation_code").hide();
  var val = $("#affiliation_code").val().toUpperCase();
  if (val != "DEMA2014"){
    $("#wrong_affiliation_code").show();
    return;
  }
  diveboard.mask_file(true);
  $.ajax({
      url: "/api/ping?utm_campaign="+val,
      dataType: 'json',
      success: function(data){
        $("#tmp_affiliation_code").hide();
        $("#wrong_affiliation_code").hide();
        $("#form_affiliation_code").hide();
        $("#ok_affiliation_code").show();
      },
      complete :function(){
        diveboard.unmask_file();
      }
    });

}