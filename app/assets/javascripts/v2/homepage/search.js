  $(document).ready(function () {
    var list = document.getElementById("suggestions");
    var full = false;
    var request = null;
    var selected_suggestion = null;
    $('.search_input').focus(function(){
      if (full) {
        list = $(this).closest("form").find(".suggestions");
        list.show();
        if (selected_suggestion != null) {
          selected_suggestion.removeClass('selected');
          selected_suggestion = null;
        }
      }
    });
    $('.search_input').blur(function(){
      list = $(this).closest("form").find(".suggestions");
        list.hide();
        if (selected_suggestion != null) {
          selected_suggestion.removeClass('selected');
          selected_suggestion = null;
        }
    });
    $('.search_input').keydown(function(e) {
      list = $(this).closest("form").find(".suggestions");
      if(e.which === 40) {
        e.preventDefault();
        if (selected_suggestion) {
          selected_suggestion.removeClass('selected');
          if (selected_suggestion.next().length > 0) {
            selected_suggestion = selected_suggestion.next().addClass('selected');
          }
          else {
            if (selected_suggestion != null) {
              selected_suggestion.addClass('selected');
            }
          }
        } else {
          if ($('#suggestions li').length > 0) {
            list.show();
            selected_suggestion = $('#suggestions').children().first().addClass('selected');
          }
        }
      } else if(e.which === 38) {
        e.preventDefault();
        if (selected_suggestion) {
          selected_suggestion.removeClass('selected');
          if (selected_suggestion.prev().length > 0) {
            selected_suggestion = selected_suggestion.prev().addClass('selected');
          }
          else {
            selected_suggestion = null;
          }
        } 
      } else if(e.which === 13) {
        if (selected_suggestion) {
          e.preventDefault();
          window.location.href = selected_suggestion.children().first().attr('href');
          list.hide();
        }
      } else if(e.which === 27) {
        list.hide();
        selected_suggestion.removeClass('selected');
        selected_suggestion = null;
      }
      console.log(selected_suggestion);
    });

    $('.search_input').on("input", function () {
      list = $(this).closest("form").find(".suggestions");
      if (!$(this).val() || $(this).val().length < 3) {
        list.hide();
        full = false;
        return;
      }
      if (request != null) {
        request.abort();
        request = null;
      }
      console.log("ajax");
      request = $.ajax(
      {
        type: "GET",
        dataType: "json",
        url : "/api/search_v2?q=" + $(this).val(),
        success : function(data) {
          console.log(data);
          if (data.success == true)
          {
            var frag = document.createDocumentFragment();
            for( var i=0; i<data.areas.length; i++ ){
              var word = document.createElement("li");
              var link = document.createElement("a");
              frag.appendChild(word);
              word.appendChild(link);
              word.link = data.areas[i].link;
              word.onmousedown = function(){          
                window.location.href = this.link;
                list.hide();
                return false;
              };  
              link.href = data.areas[i].link;
              if (data.areas[i].type == "exact"){
                link.innerHTML = "<p>" + data.areas[i].name + "</p>";
              }
              else if (data.areas[i].type == "in"){
                link.innerHTML = "<p>" + data.areas[i].search + " dive in " + data.areas[i].name + "</p>";
              }
              else if (data.areas[i].type == "near"){
                link.innerHTML = "<p>" + data.areas[i].search + " dive near " + data.areas[i].name + "</p>";
              }
              else if (data.areas[i].type == "location"){
                link.innerHTML = "<p>" + data.areas[i].name + " in " + data.areas[i].search + "</p>";
              }
            }
            if(data.areas.length){
              selected_suggestion = null;
              list.html("");
              list.append(frag);
              list.show();
              full = true;
            }
            else {
              list.hide();
              full = false;     
            }
          }
        }
      });
    });
  });