var G_events_registered = false;

$(document).ready(function(){
  initialize_follow_links(); // init the activity feed
  $('.blog_link_section.join_diveboard a').click(function(e){
    e.preventDefault();
    e.stopPropagation();
    toggle_login_popup($("#blogpostsignin"));
  });

  $("#blog_left_column").css("min-height", $("#blog_right_column").height()+"px");

  $("#post_category").change(check_category);

  share_initialize();
  $("#save_draft").click(function(e){
    e.preventDefault();
    save_post(false);
  });
  $("#publish").click(function(e){
    e.preventDefault();
    save_post(true);
  });
  $("#nodelete").click(function(e){
    e.preventDefault();
    diveboard.notify(I18n.t(["js","blog","ERROR: cannot delete"]), I18n.t(["js","blog","Sorry, since this post has already comments, you can't delete it. Please use the flag function and explain why you would want to see it deleted, a moderator will then try its best to help."]), function(){});
  });
  $("#delete").click(function(e){
    e.preventDefault();
    delete_post($(this).attr('post_id'));
  });
  $("#flag").click(function(e){
    e.preventDefault()
    flag($(this).attr('post_id'));
  });
  register_FB_events();
});


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

  diveboard.plusone_go();
}

function new_category(e){
if(e)
  e.preventDefault();

  diveboard.propose(I18n.t(["js","blog","Create a new Category"]),
    "<center><input id='new_category_input' type='text'/></center>",
    { "cancel": function(){
      $("#post_category").val("0");
    },
    "create": function()
    {
      var cat = $("#new_category_input").val();
      $("#post_category").prepend("<option value='"+cat+"'>"+cat+"</option>")
      $("#post_category").val(cat);
    }
  });

}

function check_category(e){
  if(e)
    e.preventDefault();
  if($("#post_category").val() == "-1"){
    new_category();
  }

}

function blog_post_editor(e){
  if(e){
    e.preventDefault();
    e.stopPropagation();
  }


  //text should be html
    var default_options={
    anchor: null,
    onsave_callback: null,
    oncancel_callback: null,
    editor_opts: {
        cssClass : 'el-rte blog_full_article',
        height   : 500,
        toolbar  : 'diveboardtoolbar',
        lang     : I18n.locale,
        cssfiles : ['/mod/elrte/css/elrte-inner.css', '/styles/elrte-blog.css'],
        resizable: false,
        user_id: G_user_api.id
      },
  };
  $('#blog_editor').elrte(default_options.editor_opts);
}

function save_post(ask_review){

  var data ={'authenticity_token': auth_token};
  data.text = $("#blog_editor").elrte('val').toString();
  data.title = $("#post_title").val();
  data.category = $("#post_category").val();
  data.comments_type = $("#post_comment_type").val();
  data.ask_review = ask_review;
  data.id = $("#blog_editor").attr("postid");

  if(data.text == ""){
    diveboard.notify(I18n.t(["js","blog","Error: missing text"]), I18n.t(["js","blog","Cannot save an empty post.<br/>Please type something and try again."]), function(){});
    return
  }
  if(data.title == ""){
    diveboard.notify(I18n.t(["js","blog","Error: missing title"]), I18n.t(["js","blog","Cannot save a post with no title.<br/>Please type something and try again."]), function(){});
    return
  }
  diveboard.mask_file(true)
  $.ajax({
    url:"/community/update",
    data: data,
    type:"POST",
    dataType:"json",
    error:function(){
      diveboard.alert(I18n.t(["js","blog","Could not contact server - please check your internet connection"]));
      diveboard.unmask_file();
    },
    success:function(data){
      if(data.success){
        window.location.href = data.redirect_edit;
      }else{
        diveboard.unmask_file();
        diveboard.alert(I18n.t(["js","blog","Post could not be saved"])+"<br/>"+data.error);
      }
    }
  });

}

function delete_post(id){
  var actions = {};
  actions[I18n.t(["js","blog","CANCEL"])] = function(){};
  actions[I18n.t(["js","blog","CONFIRM DELETE"])] = function(){delete_post_go(id);};
  diveboard.propose(
    I18n.t(["js","blog","Confirm delete post %{id}"], {id: id}),
    I18n.t(["js","blog","Watch out, this action is final and there is no turning back"])+"<br/>",
    actions
    );

}

function delete_post_go(id){
  diveboard.mask_file(true);
  var data = {
    'authenticity_token': auth_token,
    id: id };

  $.ajax({
    url:"/community/delete",
    data: data,
    type:"POST",
    dataType:"json",
    error:function(){
      diveboard.alert(I18n.t(["js","blog","Could not contact server - please check your internet connection"]));
      diveboard.unmask_file();
    },
    success:function(data){
      if(data.success){
        window.location.href = "/community"
      }else{
        diveboard.unmask_file();
        diveboard.alert(I18n.t(["js","blog","Post could not be saved"])+"<br/>"+data.error);
      }
    }
  });
}


function flag(id){
  $( "#dialog-global-notify .dge-text").html($("#flag_panel").html());
  $( "#dialog-global-notify").attr("title", I18n.t(["js","blog","Report an issue with post %{id}"], {id: id}));
  $( "#dialog-global-notify" ).dialog({
      resizable: false,
      modal: true,
      title: I18n.t(["js","blog","Report an issue with post %{id}"], {id: id}),
      width: '400px',
      zIndex: 99999,
      close: function(){
      },
      buttons: {
        "CANCEL": function(){
          $( this ).dialog( "close" );
        },
        "SEND REPORT": function() {
          $( this ).dialog( "close" );
          diveboard.mask_file(true)
          var data ={
            'authenticity_token': auth_token,
            id: id,
            type: "manual_report",
            text: $( "#dialog-global-notify .dge-text textarea").val()
          };
          $.ajax({
          url:"/api/report_content",
          data: data,
          type:"POST",
          dataType:"json",
          error:function(){
            diveboard.alert(I18n.t(["js","blog","Could not contact server - please check your internet connection"]));
            diveboard.unmask_file();
          },
          success:function(data){
            diveboard.unmask_file();
            if(data.success){
              diveboard.notify(I18n.t(["js","blog","SUCCESS"]), I18n.t(["js","blog","Your request has been successfully transmitted"]), function(){});
            }else{
              diveboard.alert(I18n.t(["js","blog","Could not flag post - please send us an email support@diveboard.com"])+"<br/>"+data.error);
            }
          }
          });
        }
      }
  });
}


function register_FB_events(){
  if (!G_events_registered) {
    if (typeof(FB) =="undefined"){
      setTimeout(register_FB_events, 500);
      return;
    }
    try {
      FB.Event.subscribe('comment.create', notify_event('comment.create'));
      FB.Event.subscribe('comment.remove', notify_event('comment.remove'));
      FB.Event.subscribe('edge.create', notify_event('edge.create'));
      FB.Event.subscribe('edge.remove', notify_event('edge.remove'));
      G_events_registered = true;
    } catch(e){
      console.log("Could not register FB events "+ e.message);
    }
  }
}

function notify_disqus_event(ev_type, disqus_msg) {
  $.ajax({
    url: '/api/notify_event',
    dataType: 'json',
    data: ({
      post_id: G_post_id,
      disqus_message: disqus_msg, 
      event: ev_type,
      'authenticity_token': auth_token
      }),
    type: "POST"
  });
}

function notify_event(ev_type) {
  return( function(resp) {
      $.ajax({
        url: '/api/notify_event',
        dataType: 'json',
        data: ({
          post_id: G_post_id,
          event: ev_type,
          'authenticity_token': auth_token
          }),
        type: "POST"
        });
  } );
}

function notify_google_like(data){
  var ev_type = ""
  if (data.state == "on"){
    ev_type = "google_like";}
  else{
    ev_type = "google_unlike";}

  $.ajax({
        url: '/api/notify_event',
        dataType: 'json',
        data: ({
          post_id: G_post_id,
          event: ev_type,
          'authenticity_token': auth_token
          }),
        type: "POST"
        });
}



