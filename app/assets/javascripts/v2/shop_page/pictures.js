var ShopPictures = {};
var LogoCrop;
var BannerCrop;

$(document).ready(function()
{

  var previewNode = document.querySelector("#dropzone_template");
  if (previewNode == undefined)
    return;
  previewNode.id = "";
  var previewTemplate = previewNode.parentNode.innerHTML;
  previewNode.parentNode.removeChild(previewNode); 

  var options = {
    url: "/api/picture/upload",
    autoProcessQueue: true,
    acceptedFiles: 'image/*',
    dictDefaultMessage: 'Drop files here or click to upload',
    previewTemplate: previewTemplate,
    paramName: "qqfile",
    thumbnailWidth: 180,
    thumbnailHeight: 180,
    previewsContainer: "#dropzone_content",
    init: function() {
      this.on("addedfile", function(file) { 
        _recentFile = $(file);

        //we try to set it as shop logo or cover pic
        $(file.previewElement).find('.set_as').click(function(){
          $(this).toggleClass('clicked');
          ShopPictures.setAs(this);
        });

        //Binding delete button
        $(file.previewElement).find('.delete').click(function(){
          var picId = $(this).closest('.file-row').attr("picture-id");
          ShopPictures.deletePic(picId);
        });
      });
    },
    sending: function(file, xhr, formData) {
      //formData.append("qqfile", file.name); // Will send the name of the picture chosen along with the file as POST data.
      formData.append("content_type", '/image/');
      formData.append("authenticity_token", auth_token);
      formData.append("album", "shop_gallery");
      formData.append("user_id", user_proxy_id);
      //formData.append("from_tmp_file", file.name);
    }
  };
  ShopPictures.myDropzone = new Dropzone("#picture_dropzone", options);
  ShopPictures.myDropzone.on("processing", function(file) {
    //It starts uploading the picture
    console.log(file.previewElement);

    file.interval = 0;
    file.intervalId = setInterval(function(){ 
      //every second we add 10% until we get to 90% or file has been uploaded
      if(file.interval < 90)
        ShopPictures.updateProgress(file, file.interval );
      else
        window.clearInterval(file.intervalId);
      
      file.interval ++;
    }, 100);
  });

  //Upload complete
  ShopPictures.myDropzone.on("success", function(file, server_response) {
    var picId = JSON.parse(server_response).picture.id;
    console.log(picId + " added");
    $(file.previewElement).attr('picture-id', picId);
    $(file.previewElement).find('.set').css('display', 'block');
    $(file.previewElement).find('.delete').css('display', 'block');
    ShopPictures.updateProgress(file, 100);
    
    window.clearInterval(file.intervalId);

    /*$.ajax({
      url: "/api/picture/upload",
      data: {
        user_id: ShopPictures.user_proxy_id,
        from_tmp_file: file.name,
        'authenticity_token': auth_token
      },
    });*/
  });

  $("#dropzone_content").sortable({
    placeholder: "ui-state-highlight"
  });
  $("#dropzone_content").disableSelection();

  //listener to delete pics
  $("#dropzone_content .file-row .delete").click(function(){
    var picId = $(this).closest('.file-row').attr('picture-id');
    ShopPictures.deletePic(picId);
    $(this).closest('.file-row').remove();
  });

  $(".banner_list .delete").click(function(){
    var picId = $(this).closest('li').attr('picture-id');
    ShopPictures.deletePic(picId);
    $(this).closest('li').remove();
  });

  //listener to set pics album
  $('#pictures_edit .file-row .set_as').click(function(){
    ShopPictures.setAs(this);
    $(this).toggleClass('clicked');
  });



  var previewNode = document.querySelector("#logo_template");
  previewNode.id = "";
  var previewTemplate = previewNode.parentNode.innerHTML;
  previewNode.parentNode.removeChild(previewNode); 

  var options = {
    url: "/api/picture/upload",
    maxFiles:1,
    autoProcessQueue: false,
    acceptedFiles: 'image/*',
    dictDefaultMessage: 'Choose a logo',
    previewTemplate: previewTemplate,
    paramName: "qqfile",
    thumbnailWidth: null,
    thumbnailHeight: null,
    previewsContainer: "#logo_content",
    init: function() {
      this.on("addedfile", function(file) {
        setTimeout(function (){
          $('#logo_content .preview img').Jcrop({
            aspectRatio: 1,
            keySupport: false,
            trueSize: [file.width, file.height]
          }, function()
          {
            LogoCrop = this;
          });
        }, 500);
        $("#logo_content .start").click(function() {
          LogoDropzone.processQueue();
        });
      });
      this.on("maxfilesexceeded", function(file) {
            this.removeAllFiles();
            this.addFile(file);
      });
      this.on('complete', function(file)
        {
          this.removeFile(file);
          $('#logo_content .preview').show();
          $('#logo_content .buttons').show();
        });
    },
    sending: function(file, xhr, formData) {
      //formData.append("qqfile", file.name); // Will send the name of the picture chosen along with the file as POST data.
      formData.append("content_type", '/image/');
      formData.append("authenticity_token", auth_token);
      formData.append("album", "avatar");
      formData.append("user_id", user_proxy_id);
      var crop = LogoCrop.tellSelect();
      if (crop.w != 0 && crop.h != 0)
      {
        formData.append("crop_x0", crop.x);
        formData.append("crop_y0", crop.y);
        formData.append("crop_width", crop.w);
        formData.append("crop_height", crop.h);
      }
      $('.logo_preview').addClass('load');
      $('#logo_content .preview').hide();
      $('#logo_content .buttons').hide();
      //LogoDropzone.removeFile(file)
      //formData.append("from_tmp_file", file.name);
    },
    success: function(file, response)
    {
      response = $.parseJSON(response);
      if (response.success == true)
      {
        $('.logo_preview img').attr('src', response.result.medium);
        $('.logo_preview').removeClass('load');
        $('#cover_pic .logo img').attr('src', response.result.medium);
        $('.logo_preview .delete').show();
      }
    }
  };
  LogoDropzone = new Dropzone("#logo_dropzone", options);


  var previewNode = document.querySelector("#banner_template");
  previewNode.id = "";
  var previewTemplate = previewNode.parentNode.innerHTML;
  previewNode.parentNode.removeChild(previewNode); 

  var options = {
    url: "/api/picture/upload",
    maxFiles:1,
    autoProcessQueue: false,
    acceptedFiles: 'image/*',
    dictDefaultMessage: 'Add a banner',
    previewTemplate: previewTemplate,
    paramName: "qqfile",
    thumbnailWidth: null,
    thumbnailHeight: null,
    previewsContainer: "#banner_content",
    init: function() {
      this.on("addedfile", function(file) {
        setTimeout(function (){
          $('#banner_content .preview img').Jcrop({
            aspectRatio: 4,
            keySupport: false,
            trueSize: [file.width, file.height]
          }, function()
          {
            BannerCrop = this;
          });
        }, 500);
        $("#banner_content .start").click(function() {
          BannerDropzone.processQueue();
        });
      });
      this.on("maxfilesexceeded", function(file) {
            this.removeAllFiles();
            this.addFile(file);
      });
      this.on('complete', function(file)
        {
          this.removeFile(file);
          $('#banner_content .preview').show();
          $('#banner_content .buttons').show();
        });
    },
    sending: function(file, xhr, formData) {
      //formData.append("qqfile", file.name); // Will send the name of the picture chosen along with the file as POST data.
      formData.append("content_type", '/image/');
      formData.append("authenticity_token", auth_token);
      formData.append("album", "shop_cover");
      formData.append("user_id", user_proxy_id);
      var crop = BannerCrop.tellSelect();
      if (crop.w != 0 && crop.h != 0)
      {
        formData.append("crop_x0", crop.x);
        formData.append("crop_y0", crop.y);
        formData.append("crop_width", crop.w);
        formData.append("crop_height", crop.h);
      }
      $('.banner_list').append('<li class="load"><div class="delete"></div><img src="" alt="" /></li>');
      $('#banner_content .preview').hide();
      $('#banner_content .buttons').hide();
    },
    success: function(file, response)
    {
      response = $.parseJSON(response);
      if (response.success == true)
      {
        var banner = $('.banner_list .load');
        $(banner).find('img').attr('src', response.result.large);
        $(banner).attr('picture-id', response.picture.id);
        $(banner).find('.delete').click(function()
          {
            ShopPictures.deletePic($(this).closest('li').attr('picture-id'));
            $(this).closest('li').remove();
          });
        $(banner).removeClass('load');
        $('#cover_pic').css('background-image', "url('" + response.result.large + "')");
      }
    }
  };
  BannerDropzone = new Dropzone("#banner_dropzone", options);

  // Delete Shop Logo Listener
  if ($('.logo_preview img').attr('src').indexOf('icon_shop_default.png') >= 0)
    $('.logo_preview .delete').hide();
  $('.logo_preview .delete').click(function()
    {
      $.ajax({
        url: '/api/shop/remove_logo',
        data: {"user_id": user_proxy_id},
        type: 'POST'
      });
      $(this).hide();
      $('.logo_preview img').attr('src', window.location.origin + '/img/shop/icon_shop_default.png');
      $('#cover_pic .infos .logo img').attr('src', window.location.origin + '/img/shop/icon_shop_default.png');
    });
});

//Ajax call to delete the pic
ShopPictures.deletePic = function(picId){
  console.log(picId);
  $.ajax({
    url: '/api/V2/picture/' + picId,
    type: 'DELETE'
  });

};

ShopPictures.setAs = function(tag){
  if ($(tag).hasClass('logo'))
  {
    if ($(tag).hasClass('clicked'))
    {
      $(tag).closest('.file-row').find('.status_success').html('');
    }
    else
    {
      $(tag).closest('.file-row').find('.status_success').html('Logo');
      //$('#cover_pic .logo').css('display', 'block');
      //$('#cover_pic .logo img').attr('src', $(file.previewElement).find('.preview img').attr('src'));
      var data = {
        'authenticity_token': auth_token,
        'arg': JSON.stringify({'id': $('#shop_id').val(), 'picture': $(tag).closest('.file-row').attr('picture-id')})
      };
      console.log(data);

      $.ajax({
        url: '/api/V2/shop',
        dataType: 'json',
        data: data,
        type: "POST",
        success: function(data)
        {
          console.log(data);
        }
      });
    }
  }
  else if ($(tag).hasClass('cover'))
  {
    if ($(tag).hasClass('clicked'))
    {
      $(tag).closest('.file-row').find('.status_success').html('');
    }
    else
    {
      $(tag).closest('.file-row').find('.status_success').html('Cover');
    }
    //file.shop_id = ShopPictures.user_proxy_id;
  }
  
};

ShopPictures.updateProgress = function(file, progress){
  $(file.previewElement).find('.progress-bar').css('width', progress + "%");

};