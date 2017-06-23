$(document).ready(function(){
  $(".check_fb_likes").on("click",check_fb_likes);

});

var email = "";

function check_fb_likes(){

  FB.login(function(response) {

    var suunto_id = "79617532620"; //Suunto
    var diveboard_id = "140880105947100"
    var suunto = false;
    var diveboard = false;
/*
    FB.api('/me/likes/'+suunto_id, function(response) {
      if (response.data[0]) {
        suunto = true;
        if(suunto && diveboard){
          submit_like()
        }
      } 
    });
    FB.api('/me/likes/'+diveboard_id, function(response) {
      r = response;
      if (response.data[0]) {
          diveboard = true;
        if(suunto && diveboard){
          submit_like()
        }
      } 
    });
*/
  FB.api('/me', function(userInfo) {
    email = userInfo.email;
    submit_like();
  });

  }, {scope: 'email'});

}

function submit_like(){
  //TODO SUBMIT
   var data_to_send = {
    'object_id': 0,
    'object_type': "fb-like",
    'campaign_name': email || "movescount",
    'authenticity_token': auth_token,
    utf8: "&#x2713;"
  }
  $.ajax({
    url: '/api/V2/contest',
    dataType: 'json',
    data: data_to_send,
    type: "POST",
    success: function(data){
      if (data.success){
        $("#chip1").text("1");
      }
      else{
        alert("Could not save your chip");
      }
    },
    error: function(data){
      
    }
  });
}