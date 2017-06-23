var G_species_picker_scope = "local";
var G_species_picker_never_shown = true;
var G_search_result=[];
var G_search_result_paginate = {};
var G_search_query = {};
var G_species_picker_data_source = new Object;
var G_species_picker_page_size = 50;
var G_bindings_set= false;

$(document).ready(function(){
  if(document.readyState === "complete" ) {
      load_all_species_js();
  }
  else if(document.addEventListener) {
      window.addEventListener("load", load_all_species_js, false );
  }
  else if(window.attachEvent) {
      window.attachEvent("onload", load_all_species_js);
  }
});


function init_bindings(){
  //init species_picker related stuff
  //init_species_picker();
  if(G_bindings_set)
    return;
  else
    G_bindings_set = true;

  update_my_species_count();
  //species_data comes from the included js - it has the data of the local species
  update_species_picker(G_species_picker_data_source);



  $(".species_picker_frame ul.species_picker_pagination li").live({
    click: function(e){
    e.preventDefault();

    change_to_page($(this).attr("name"));
    }
  });


  $(".species_picker_frame .species_picker_page_link span").live({
    click: function(e){
    e.preventDefault();

    change_to_page($(this).attr("name"));
    }
  });

  $(".species_picker_frame .species_categories li").live({
      mouseenter: function() {
        highlight_category(this);
      },
      mouseleave: function() {
        unhighlight_category(this);
      }
  });

  $(".species_picker_frame .species_picker_left li").live({
      click: function(){
        if($(this).hasClass("my_species")){
          unselect_all_categories();
          $(this).addClass("selected");
          highlight_category(this);
          show_my_species();
        }else if($(this).hasClass("search_species"))
          $(".species_picker_frame .search_scope input").click();
        else if($(this).hasClass("selected_species"))
          show_selected_species();
        else
          select_category(this);
      }
  });
  $(".species_picker_frame .add_species_button").live({
    click: function(){
      if($(this).hasClass("green")){
        //we're adding a species
        add_species(JSON.parse($(this).attr("data")));
        $(this).removeClass("green").addClass("orangenohover");
      }else if ($(this).hasClass("orangenohover")){
        //nothing to do
      }else{
        //removing a species
        remove_species(JSON.parse($(this).attr("data")));
        $(this).removeClass("orange").removeClass("orangenohover").addClass("green");
        if($(".species_picker_frame .species_picker_left li.selected").hasClass("selected_species")){
          //we need to remove from selection and reorder
          $(this).closest(".species_items").remove();
          rearrange_species_pictures();
        }
      }
    }
  });

  $(".species_items .orangenohover").live({
    mouseleave: function(){
      $(this).addClass("orange").removeClass("orangenohover");
    }
  })

  $(".species_items .species_image_holder").live({
    mouseenter: function() {
      add_hover(this);
    },
    mouseleave: function() {
      delete_hover(this);
    }
  });
  $(".species_picker_frame .search_scope input").click(function(){
    update_species_picker_scope($(".search_scope input:checked").val());
  })
  $(".species_picker_frame .species_picker_search").keydown(search_species_name);
  $(".species_picker_frame .search_symbol").click(search_species_name);


  $(".species_picker_frame .species_items .search_species_children").live({click: function(e){
   e.preventDefault(); search_species_hierarchy("children",JSON.parse($(this).closest(".species_items").find(".add_species_button").attr("data")).id);
  }});
  $(".species_picker_frame .species_items .search_species_siblings").live({click: function(e){
   e.preventDefault(); search_species_hierarchy("siblings",JSON.parse($(this).closest(".species_items").find(".add_species_button").attr("data")).id);
  }});
  $(".species_picker_frame .species_items .search_species_ancestors").live({click: function(e){
   e.preventDefault(); search_species_hierarchy("ancestors",JSON.parse($(this).closest(".species_items").find(".add_species_button").attr("data")).id);
  }});



}

function select_category(element){
  unselect_all_categories();
  $(element).addClass("selected");
  highlight_category(element);

  show_species(G_species_picker_data_source[$(element).attr("name")]);

}


function highlight_category(element){
  if(!$(element).hasClass("selected")){
    if (!$(element).prevAll(".species_picker_frame .species_categories li:visible").first().hasClass("selected")){
      $(element).prevAll(".species_picker_frame .species_categories li:visible").first().css("border-bottom", "1px solid #EBEBEB");
     // $(element).css("margin-top","1px");
    }else{
     // $(element).css("padding-top","9px");
    }
    if (!$(element).nextAll(".species_picker_frame .species_categories li:visible").first().hasClass("selected")){
      $(element).nextAll(".species_picker_frame  .species_categories li:visible").first().css("border-top", "1px solid #EBEBEB");
      //$(element).css("margin-bottom","0px");
    }else{
    }
  }
}

function unhighlight_category(element){
  if(!$(element).hasClass("selected")){
    if (!$(element).prevAll(".species_picker_frame .species_categories li:visible").first().hasClass("selected")){
      $(element).prevAll(".species_picker_frame .species_categories li:visible").first().css("border-bottom", "1px solid #BEBEBE");
      //$(element).css("margin-top","0px");
    }else{

    }
    if (!$(element).nextAll(".species_picker_frame .species_categories li:visible").first().hasClass("selected")){
      $(element).nextAll(".species_picker_frame  .species_categories li:visible").first().css("border-top", "1px solid #BEBEBE");
      //$(element).css("margin-bottom","-1px");
    }

  }
}

function unselect_category(element){
  $(element).removeClass("selected");
}

function unselect_all_categories(){
  //also hide the search - no point on keeping it
  $(".species_picker_frame .search_species").hide();
    $.each($(".species_picker_frame .species_picker_left li.selected"), function(index, value){
      $(value).removeClass("selected");
      unhighlight_category(value);
      });

}

function update_species_picker(list){
  //let's start by setting the counter for my species
  update_my_species_count();

  var save_current_category = $(".species_picker_frame li.selected");
  //console.log("savign currently selected category : "+ save_current_category);
  var has_other = false;
  $.each( $( ".species_picker_frame .species_categories li" ), function(index, value){
    if (!$(value).hasClass("sticky_picker"))
      $(value).remove();
  });
  //var keys = Object.keys(list);
  var keys = [];
  $.each(list, function(key, value) {
      keys.push(key);
  });
  keys.sort(function(a, b) {
     var compA = list[a].length;
     var compB = list[b].length;
     return (compA < compB) ? -1 : (compA > compB) ? 1 : 0;
  })

  $.each(keys.reverse(), function(index, value){
    if (value != "other")
      $( ".species_picker_frame .species_categories").append("<li name='"+value+"'>"+value+"<span>"+list[value].length+"</span></li>");
    else
      has_other=true;
  })
  if(has_other)
    $( ".species_picker_frame .species_categories").append("<li name='other' >Other<span>"+list['other'].length+"</span></li>");

  if(save_current_category.length != 0){
    if (save_current_category.attr("name") != undefined)
      $(".species_picker_frame li[name='"+save_current_category.attr("name")+"']").click();
    else if (save_current_category.hasClass("search_species") && G_search_query.name != undefined && G_search_query.name.length >=3)
      $(".species_picker_frame .search_symbol").click();
    else if (save_current_category.hasClass("search_species"))
      $(".species_picker_frame li.selected_species").click();
    else if (save_current_category.hasClass("selected_species"))
      $(".species_picker_frame li.selected_species").click();
    else if (save_current_category.hasClass("my_species"))
      $(".species_picker_frame li.my_species").click();
    else
      $(".species_picker_frame li.selected_species").click();
  }else
    $(".species_picker_frame li.selected_species").click();
}

function show_species(species_input, page){

  if($(".species_picker_frame li.selected").hasClass("selected_species")){
    if(page == undefined)
      page = 1;
    var total_pages = Math.floor(species_input.length/G_species_picker_page_size)+1;
    var current_page= page;
  }else if($(".species_picker_frame li.selected").hasClass("my_species")){
    if(page == undefined)
      page = 1;
    var total_pages = Math.floor(species_input.length/G_species_picker_page_size)+1;
    var current_page= page;
  }else if($(".species_picker_frame li.selected").hasClass("search_species")){
    if($(".search_scope input:checked").val() == "all")
      page =1; // from the server we only get the current page so no need to slice it
    else
      page = G_search_result_paginate.current_page;
    var current_page = G_search_result_paginate.current_page;
    total_pages = G_search_result_paginate.total_pages;
  }else if((save_current_category = $(".species_picker_frame li.selected").attr("name")) != undefined){
    if(page == undefined)
      page = 1;
    var total_pages = Math.floor(species_input.length/G_species_picker_page_size)+1;
    var current_page= page;
  }else{
    //console.log("We're lost in show_species...");
  }



  // we get the page from the array.
  var species = species_input.slice((page-1)*G_species_picker_page_size, page*G_species_picker_page_size);

  empty_and_add_loader_mask();
  $(".species_picker_frame .species_picker_right").append("<div class='species_item_holder clearfix'></div>");



  if(total_pages > 1){
    add_pagination(current_page, total_pages);
  }
  var sp_pict=[];
  var sp_nopict = [];
  $.each(species, function(index, value){
    if(value.picture == null || value.picture == ""){
      value.picture = "/img/picture_placeholder.png";
      sp_nopict.push(value);
    }
    else
      sp_pict.push(value);
  });

  var species_ordered = sp_pict.concat(sp_nopict);
  var selected_species_list = {}
  $.each(G_dive_fishes, function(index,value){
    selected_species_list[value.id] = true;
  });


  $.each(species_ordered, function(index, value){
    var line = generate_species_thumb(value, index, selected_species_list);


    var added_line = $(".species_picker_frame .species_picker_right div.species_item_holder").append(line);
    $(".species_picker_frame .species_picker_right #species_item_holder_"+index).find(".add_species_button").attr("data", JSON.stringify(value));

    if (value.bio != "" && typeof(value.bio) != "undefined")
      $(".species_picker_frame .species_picker_right #species_item_holder_"+index).find(".species_picker_mask a.tooltipped-species").attr("title", value.bio+"<br/>"+I18n.t(["js","species_picker","Source:"])+" <a href='"+value.url+"'>EOL</a>");



  });

  //render a nice layout
  $(".species_picker_frame .species_picker_right .species_item_holder").removeClass('masonry');
  $(".species_picker_frame .species_picker_right .species_item_holder").css("width", ($(".species_picker_frame").width()-220)+"px");

  $(".species_picker_frame .species_picker_right .species_item_holder").imagesLoaded( function(){
    del_species_loader_mask();
    rearrange_species_pictures();
  });
}

function add_species(species){
  G_dive_fishes.push(species);
  update_my_species_count();
}

function remove_species(species){
  //console.log("removing : "+JSON.stringify(species));
  var dive_species = [];
  $.each(G_dive_fishes, function(index, value){ if(value.id != species.id){dive_species.push(value);}   })
  G_dive_fishes =  dive_species;
  update_my_species_count();
  remove_species_from_pictures(species.id);
}

function add_hover(obj){
  $(obj).find(".species_picker_mask").css({
      width: "150px",
      height: "auto",
      'min-height': ($(obj).find("img").height()-5)+"px",
      top: ($(obj).find("img").position().top)+"px",
      left: ($(obj).find("img").position().left)+"px"}).show();
      if ( !$(obj).find(".species_picker_mask a.tooltipped-species").hasClass("tooltip_rendered")){
        //avoiding double renders of qtip
        $(obj).find(".species_picker_mask a.tooltipped-species").qtip({
            style: {
              tip: { corner: true },
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
          }).addClass("tooltip_rendered");
      }
}

function delete_hover(obj){
  $(obj).find(".species_picker_mask").hide();
}

function show_my_species(){
  //console.log("my species");
  show_species(G_user_identified_species);
}

function show_search_species(){
  //console.log("search species");
  show_search_results(G_search_result);
}

function show_selected_species(){
  //console.log("selected species");
  var element = $(".species_picker_frame .species_picker_left .selected_species");
  unselect_all_categories();
  $(element).addClass("selected");
  highlight_category(element);
  show_species(G_dive_fishes);
}

function update_my_species_count(){
   $(".species_picker_frame .species_picker_left .selected_species span").html(G_dive_fishes.length);
   $(".species_picker_frame .species_picker_left .my_species span").html(G_user_identified_species.length);
}

function rearrange_species_pictures(){
  $(".species_picker_frame .species_picker_right .species_item_holder").masonry({
    itemSelector : '.species_items',
    columnWidth : 170
  });
}

function update_species_picker_scope(scope){
  //console.log("new scope is: "+scope);
  G_species_picker_scope = scope;
  if (G_species_picker_scope == "local")
    G_species_picker_data_source = species_data
  else
    G_species_picker_data_source = species_data_all

  update_species_picker(G_species_picker_data_source);
}

function load_all_species_js(){
  //will load the big guy after the page laod is complete
  var a = document.createElement('script');
      a.type = 'text/javascript';
      a.async = true;
      a.src = '/assets/species/species_data_all.js';
      var b = document.getElementsByTagName('script')[0];
      b.parentNode.insertBefore(a, b);
}

function appendScript (parent, scriptElt, listener) {
    //from http://stackoverflow.com/questions/774752/dynamic-script-loading-synchronization
    //
    // append a script element as last child in parent and configure
    // provided listener function for the script load event
    //
    // params:
    //   parent - (DOM element) (!nil) the parent node to append the script to
    //   scriptElt - (DOM element) (!nil) a new script element
    //   listener - (function) (!nil) listener function for script load event
    //
    // Notes:
    //   - in IE, the load event is simulated by setting an intermediate
    //     listener to onreadystate which filters events and fires the
    //     callback just once when the state is "loaded" or "complete"
    //
    //   - Opera supports both readyState and onload, but does not behave in
    //     the exact same way as IE for readyState, e.g. "loaded" may be
    //     reached before the script runs.

    var safelistener = function(){
      try {
        listener();
      } catch(e) {
        // do something with the error
      }
    };

    // Opera has readyState too, but does not behave in a consistent way
    if (scriptElt.readyState && scriptElt.onload!==null) {
      // IE only (onload===undefined) not Opera (onload===null)
      scriptElt.onreadystatechange = function() {
        if ( scriptElt.readyState === "loaded" ||
             scriptElt.readyState === "complete" ) {
          // Avoid memory leaks (and duplicate call to callback) in IE
          scriptElt.onreadystatechange = null;
          safelistener();
        }
      };
    } else {
      // other browsers (DOM Level 0)
      scriptElt.onload = safelistener;
    }
    parent.appendChild( scriptElt );
};

function update_species_list(lat, lng){
  var lati = Math.round(Number(lat)/5)*5;
  var lngi = Math.round(Number(lng)/5)*5;
  var a = document.createElement('script');
      a.type = 'text/javascript';
      a.async = true;
      a.src = '/assets/species/species_data_'+lati+'_'+lngi+'_5.js';
      var b = document.getElementsByTagName('script')[0];
      //b.parentNode.insertBefore(a, b);
/*
  appendScript(b, a, function(){
      update_species_picker_scope($(".search_scope input:checked").val());
      //get back to a "stable" state - on the "selected species tab"
      // without timeout, we get species x3 ... no idea why ...
      setTimeout(function(){$(".species_picker_frame li.selected_species").click();}, 500);
  });
*/
  $.ajax({
  url: a.src,
  dataType: "script",
  success: function(){
    update_species_picker_scope($(".search_scope input:checked").val());
    //get back to a "stable" state - on the "selected species tab"
    // without timeout, we get species x3 ... no idea why ...
    setTimeout(function(){$(".species_picker_frame li.selected_species").click();}, 500);
  }
});
}

function search_species_hierarchy(level, id){
  search_species_ajax({
    'authenticity_token': $("meta[name='csrf-token']").attr("content"),
    id: id,
    scope: level
  });

}
function search_species_name(e, page){
  if (e == undefined || typeof(e.keyCode) == "undefined" || e.keyCode ==13 ){

    if(e==undefined){
      if(page==undefined){
       G_search_query = null;
       G_search_result_paginate = null;
     }
    }else
      e.preventDefault();

    empty_and_add_loader_mask();
    var name = $(".species_picker_frame .species_picker_search").val();
    if (page==undefined)
      page = 1;
    else if (page >= 1){//we replay the previous query
        $(".species_picker_frame .species_picker_search").val(G_search_query.name);
        name = G_search_query.name;
    }
    if(name.length < 3){
      diveboard.notify(I18n.t(["js","species_picker","Error"]),I18n.t(["js","species_picker","The search term must be at least 3 characters"]));
      del_species_loader_mask();
      return;
    }
    //console.log("Searching for "+name);
    if($(".search_scope input:checked").val() == "all"){

      //console.log("searchin on server");
      search_species_ajax({
        'authenticity_token': $("meta[name='csrf-token']").attr("content"),
         name: name,
         page: page,
         page_size: G_species_picker_page_size
      });
    }
    else{
      //console.log("searching locally");
      G_search_query = {name: name};
      //var keys = Object.keys(species_data);
      //IE compatible version...
      var keys = [];
      $.each(species_data, function(key, value) {
          keys.push(key);
      });

      var result = [];
      var result_other = [];
      var name_rgxp = new RegExp(name.split(" "), "i");
      $.each(keys, function(index,value){
        if (value != "other")
          $.each(species_data[value], function(index,value){
            if(JSON.stringify(value.cnames).match(name_rgxp) || value.sname.match(name_rgxp))
              result.push(value);
          });
        else
          $.each(species_data[value], function(index,value){
            if(JSON.stringify(value.cnames).match(name_rgxp) || value.sname.match(name_rgxp))
              result_other.push(value);
          });
      });
      var total_result = result.concat(result_other);
      var total_pages = Math.floor(total_result.length/G_species_picker_page_size)+1;
      if(total_pages>page)
        var next_page =page+1;
      else
        var next_page = null;

      if(page>1)
        var prev_page = page-1;
      else
        var prev_page =null

      var paginate = {total: total_result.length, next: next_page, previous: prev_page, total_pages: total_pages, current_page: page};
      show_search_results(total_result,paginate);
    }
  }
}

function search_species_ajax(call){
  empty_and_add_loader_mask();
  G_search_query = call;
  $.ajax({
    url: "/api/fishsearch_extended",
    data: call,
    type: "POST",
    dataType: "json",
    error: function(data) { diveboard.alert(I18n.t(["js","species_picker","A technical error happened while creating the dive from the uploaded profile."])); del_species_loader_mask();},
    success: function(data) {
      if(data.success){
        //console.log(data.result);
        show_search_results(data.result, data.paginate);
      }else{
        del_species_loader_mask();
        diveboard.notify("Error","Search failed");

      }
    }
  });

}

function show_search_results(result, paginate){
  G_search_result = result;
  //if(typeof(paginate) != "undefined")
  G_search_result_paginate = paginate;


  unselect_all_categories();
  $(".species_picker_frame .search_species span").html(G_search_result_paginate.total).show();
  $(".species_picker_frame .search_species").show();
  highlight_category($(".species_picker_frame .search_species")[0]);
  $(".species_picker_frame .search_species").addClass("selected");
  //TODO : remove species that were not in scope local if this is what is asked

  //TODO : ADD prev/next buttons for pagination

  show_species(result);
}

function init_species_picker(){
  //we need the species picker to be visible for it to be properly initialized
  init_bindings();
  if(G_species_picker_never_shown){
    if($(".species_picker_frame").is(":visible") && typeof(species_data) != "undefined"){
      //console.log("species data present "+ typeof(species_data));
      G_species_picker_data_source = species_data;
      update_species_picker(G_species_picker_data_source);
      //show_selected_species();
      G_species_picker_never_shown = false;
    }else{
      //console.log("no species data");
      setTimeout(init_species_picker, 500);
    }
  }
}

function add_pagination(page, total_pages){
  //console.log("adding pagination "+page+" and total page"+total_pages);
  var p = "<ul class='species_picker_pagination'>";
  if(total_pages < 7){
    for(var i = 1 ; i <= total_pages ; i++){
      p +="<li name='"+i+"'";
      if (i == page)
        p += "class='selected_page'";
      p +=">"+i+"</li>";
    }

  }else if (total_pages >=7 && page < 4){
    for(var i = 1 ; i <= Math.max(5,page+2) ; i++){
      p +="<li name='"+i+"'";
      if (i == page)
        p += "class='selected_page'";
      p +=">"+i+"</li>";
    }
    p += "<li class='separator'>...</li>";
    p += "<li name='"+total_pages+"'>"+total_pages+"</li>";
  }else if (total_pages >=7 && page > total_pages -4){
    p += "<li name='1'>1</li>";
    p += "<li class='separator'>...</li>";
    for(var i = total_pages -4 ; i <= total_pages ; i++){
      p +="<li name='"+i+"'";
      if (i == page)
        p += "class='selected_page'";
      p +=">"+i+"</li>";
    }
  }else{
    p += "<li name='1'>1</li>";
    p += "<li class='separator'>...</li>";
    for(var i = page-2 ; i <= page+2 ; i++){
      p +="<li name='"+i+"'";
      if (i == page)
        p += "class='selected_page'";
      p +=">"+i+"</li>";
    }
    p += "<li class='separator'>...</li>";
    p += "<li name='"+total_pages+"'>"+total_pages+"</li>";
  }

  p +="</ul>";

  p +="<div class='species_picker_page_link'>";
  if (page > 1)
    p += "<span name='"+(page-1)+"'>Prev</span>";
  if (page > 1 && page < total_pages)
    p += "<p>/</p>";
  if (page < total_pages)
    p += "<span name='"+(page+1)+"'>Next</span>";
  p += "</div>";

  $(".species_picker_frame .species_picker_right").prepend(p); // adding to the DOM
}

function change_to_page(number){
  //change to page XX
  num = Number(number);
  $(".species_picker_frame .species_picker_right").empty();
  //console.log("Changing to page "+num);
  var save_current_category = null;
  if($(".species_picker_frame li.selected").hasClass("selected_species")){
    //We're paginating on the selected species pane
  }else if($(".species_picker_frame li.selected").hasClass("my_species")){
    show_species(G_user_identified_species, num);
  }else if($(".species_picker_frame li.selected").hasClass("search_species")){
    //we need to search on next page
    search_species_name(undefined, num);
  }else if((save_current_category = $(".species_picker_frame li.selected").attr("name")) != undefined){
    show_species(G_species_picker_data_source[save_current_category],num);
  }else{
    //console.log("We're lost...");
  }
}
function empty_and_add_loader_mask(){
  if($(".species_picker_frame .species_picker_right .species_file_mask_right").length == 0){
    $(".species_picker_frame .species_picker_right").empty();
    var p = "<div class='species_file_mask_right'><center><img src='/img/transparent_loader_2.gif' height='66px' width='66px'/></center></div>";
    $(".species_picker_frame .species_picker_right").append(p);
    $(".species_picker_frame .species_picker_page_link").hide()
    $(".species_picker_frame .species_picker_right div.species_item_holder").hide();
  }
}

function del_species_loader_mask(){
  $(".species_picker_frame .species_picker_right .species_file_mask_right").remove();
  $(".species_picker_frame .species_picker_page_link").css("display", "inline-block");
  $(".species_picker_frame .species_picker_right div.species_item_holder").show();
}


function generate_species_thumb(value, index, selected_species_list, show_search){
  if(show_search == undefined)
    var show_search = true;

  if(value.preferred_name == "" || value.preferred_name == null){
      var name = value.sname;
      var scientific_name = "";
  }else{
    var name = value.preferred_name;
    var scientific_name = "<p><b><em>"+value.sname+"</em></b></p>";
  }

  if(selected_species_list[value.id])
    var status ="orange";
  else
    var status = "green";

  if(value.rank == "species")
    var family = "<a href='#' class='search_species_siblings'>"+I18n.t(["js","species_picker","siblings"])+"</a>, <a href='#' class='search_species_ancestors'>"+I18n.t(["js","species_picker","ancestors"])+"</a>";
  else if (value.rank == "kingdom")
    var family = "<a href='#' class='search_species_children'>"+I18n.t(["js","species_picker","children"])+"</a>";
  else
    var family = "<a href='#' class='search_species_siblings'>"+I18n.t(["js","species_picker","siblings"])+"</a>, <a href='#' class='search_species_ancestors'>"+I18n.t(["js","species_picker","ancestors"])+"</a>, <a href='#' class='search_species_children'>"+I18n.t(["js","species_picker","children"])+"</a>";

  if (value.bio != "" && typeof(value.bio) != "undefined")
    var biodata = "<p>"+I18n.t(["js","species_picker","Check <a href='#' class='tooltipped-species' onclick='return false;'>biological information</a>"])+"</p>";
  else
    var biodata = "";

  var line = "<div class='species_items' id='species_item_holder_"+index+"'>\
    <table border='0' cellspacing='0' cellpadding='0'>\
      <tr>\
        <td class='species_name'>"+name+"</td>\
        <td class='add_species_button "+status+"'>\
          <span class='green'>+</span>\
          <span class='symbol orange'>.</span>\
          <span class='red'>-</span>\
        </td>\
      </tr>\
    </table>\
    <div class='species_image_holder'>\
      <img src='"+ value.picture +"' width='150'/>\
      <div class='species_picker_mask' style='display:none;'>\
        "+scientific_name+"\
        <p>"+I18n.t(["js","species_picker","Rank:"])+" <b>"+I18n.t(["js","species_picker","ranks", value.rank])+"</b></p>";

   if(show_search)
        line+= "<p>"+I18n.t(["js","species_picker","Search %{family}"], {family: family})+"</p>"
    line+=biodata+"\
      </div>\
    </div>\
    </div>";

  return line;
}



//////////////////////////////////////
// minipicker : will create a multipicker following the same look and feel as big picker
// but no categories and selection remains in current pane
//////////////////////////////////////
var G_multipicker_bindings=false;
function build_minipicker(id, position, species_list, current, callback){
  //id: the jquery ad of the element we will anchor to (ie appear below)
  //species list : the lit of species to choose from, following the usual format
  //current: selected species : the list of currently selected species [id1, id2, id3...]
  //callback : the callback function called when a species is added
  //position : if it's a string it's a selector and goes there if it's a hash {top, left} absolute position if it's a "object"
  //WARNING this code is largely a duplicate from

  var container = null;
  if(typeof(position) == "string"){
    container = $(position);
    container.addClass("multipicker");
  }else if(typeof(position) == "object" && position.length != undefined){
    //it's a jquery selectol
    //This is used in the picture editor
    container = position;
    var d  = "<div id='multipicker_"+id+"' class='multipicker'>";
        d += "</div>"
    container.append(d); // create the holder
    container = container.find("div");
  }else if(typeof(position) == "object" && position.length == undefined){
    //it's a position
    var d  = "<div id='multipicker_"+id+"' class='multipicker'>";
        d += "</div>"
    $("body").append(d); // create the holder
    container = $("#multipicker_"+id);
    //render a nice layout
    container.css("position", "absolute");
    container.css("left", position.left+"px");
    container.css("top", position.top+"px");
  }

  var sp_pict=[];
  var sp_nopict=[];
  $.each(species_list, function(index, value){
    if(value.picture == null || value.picture == ""){
      value.picture = "/img/picture_placeholder.png";
      sp_nopict.push(value);
    }
    else
      sp_pict.push(value);
  });
  var species_ordered = sp_pict.concat(sp_nopict);
  var selected_species_list = {}
  $.each(current, function(index,value){
    selected_species_list[value] = true;
  });

  $.each(species_ordered, function(index, value){
     var line = generate_species_thumb(value, index, selected_species_list, false);
    var added_line = container.append(line);
    container.find("#species_item_holder_"+index).find(".add_species_button").attr("data", JSON.stringify(value));

    if (value.bio != "" && typeof(value.bio) != "undefined")
      container.find("#species_item_holder_"+index).find(".species_picker_mask a.tooltipped-species").attr("title", value.bio+"<br/>"+I18n.t(["js","species_picker","Source:"])+" <a href='"+value.url+"'>EOL</a>");
  });

  $("#multipicker_"+id).imagesLoaded( function(){
    //console.log("calling masonry on #multipicker_"+id);
    $("#multipicker_"+id).masonry({
      itemSelector : '.species_items',
      columnWidth : 170
    });
  });
  if(!G_multipicker_bindings){
    $(".multipicker .add_species_button").live({
      click: function(){
        if($(this).hasClass("green")){
          //we're adding a species
          //add_species(JSON.parse($(this).attr("data")));
          //console.log("adding species minipicker");
          $(this).removeClass("green").addClass("orangenohover");
        }else{
          //removing a species
          //remove_species(JSON.parse($(this).attr("data")));
          //console.log("removing species minipicker");
          $(this).removeClass("orange").addClass("green");
        }
      }
    });
    G_multipicker_bindings = true;
  }

}


function report_missing_species(){
  missing_species_id = null;
  buttons = {};
  buttons[I18n.t(["js","species_picker","Cancel"])] = function(){return;}
  buttons[I18n.t(["js","species_picker","Add species"])] = function(){add_missing_species(missing_species_id);}
  diveboard.propose(I18n.t(["js","species_picker","Missing species"]), I18n.t(["js","species_picker","To add a missing species proceed as follow:"])
    , buttons);
}

function add_missing_species(species_id){
  diveboard.mask_file(true);
  $.ajax({
    url: "/api/add_missing_species",
    data: {
      species_eol_id: species_id,
      'authenticity_token': auth_token
    },
    type: "POST",
    dataType: "json",
    error: function(data) { diveboard.alert(I18n.t(["js","species_picker","A technical error happened"])); diveboard.unmask_file();},
    success: function(data) {
      if(data.success){
        diveboard.unmask_file();
        diveboard.notify(I18n.t(["js","species_picker","Success"]), I18n.t(["js","species_picker","Species has been successfully added to database.<br/><br/><b>In about one minute</b><br/><br/>(While import tasks finish up) you should be able to search and add this species using the top search field with 'all' scope."])+"<br/>");
      }else{
        diveboard.unmask_file();
        diveboard.notify(I18n.t(["js","species_picker","Error"]), I18n.t(["js","species_picker","Something went wrong: %{error} please open a support ticket if appropriate"], {error: data.error}));
      }
    }
  });
}


