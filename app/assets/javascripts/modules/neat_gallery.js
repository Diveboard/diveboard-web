(function($){

  $.fn.neat_gallery = function(argument) {
    var defaults = {
      source: dive_pictures_data,
      width: 400,
      max_height: 80,
      widthMargin: 120,
      onclick: function(idx, img, event){},
      cover: true,
      coverRows: 2,
      coverIndex: 0,
      coverForceFirst: true,
      margin: 1,
      loading: function(){},
      loaded: function(){},
      editable: false,
      flag_isLoading: false
    };

    var destination_div = this;


    var pack_images = function(start, target_width, excluding) {
      var current_line_width = 0.0;
      var pack_all = [];
      var pack_last = [];
      var pack_length = [];
      var cursor;
      //console.log("excluding");
      //console.log(excluding);
      for (cursor = start; cursor < local_data.all_img.length && local_data.all_img[cursor].loaded; cursor++) {
        if (!excluding || $.inArray(cursor, excluding)<0) {
          current_line_width += local_data.all_img[cursor].width * 1.0 * local_data.options.max_height / local_data.all_img[cursor].height;
          pack_last.push(cursor);
        }
        //console.log("pack:"+current_line_width);
        if (current_line_width >= target_width - (pack_last.length-1) * local_data.options.margin) {
          pack_length.push(current_line_width);
          pack_all.push(pack_last);
          pack_last = [];
          current_line_width = 0.0;
        }
      }

      if (pack_last.length > 0){
        pack_length.push(current_line_width);
        pack_all.push(pack_last);
      }

      return ({
        packs: pack_all,
        widths: pack_length,
        lastNotComplete: pack_last.length > 0,
        hasMore: (cursor < local_data.all_img.length)
      });
    }


    //This function adds the images that are ready until it founds one not ready
    var append_ready = function() {
      //console.log("Running append_ready - "+local_data.current_line_cursor);
      var target_width = local_data.options.width;
      var packs;

      if (local_data.options.flag_isLoading) return;


      //Displays the cover
      if (local_data.options.cover && local_data.current_line_cursor == 0 )
      {
        var cover_img = local_data.all_img[local_data.options.coverIndex];
        var cover_width;
        var current_coverRows = local_data.options.coverRows;

        while ( (cover_width = current_coverRows * cover_img.width * local_data.options.max_height / cover_img.height) > target_width && current_coverRows > 0) {
          current_coverRows--;
        }

				var cover_height = current_coverRows * local_data.options.max_height;

        if (cover_width > target_width) {
          cover_width = target_width;
          cover_height = cover_img.height * target_width / cover_img.width;
        }

        packs = pack_images(local_data.current_line_cursor, target_width-cover_width, [ local_data.options.coverIndex ]);
        //console.log(packs);
        if (packs.packs.length <= current_coverRows && packs.hasMore)
          return;

        var head = $("<div></div>");
        var head1 = $("<div></div>").css('display', 'inline-block');
        var head2 = $("<div></div>").css('display', 'inline-block');
        head.append(head1);
        head.append(head2);
        head.css('width', local_data.options.width + 2*local_data.options.widthMargin + 10);
        head2.css('width', target_width -cover_width + local_data.options.widthMargin + 5);
        cover_img.obj.css('height', cover_height);
        cover_img.obj.css('width', cover_width);
        head1.append(cover_img.obj);
				var heightSum = 0.0;
        for (var i=0; i<current_coverRows && i<packs.packs.length; i++) {
          var fullLine = (i<packs.packs.length-1 || packs.hasMore || !packs.lastNotComplete);
          //console.log(fullLine);
          var line = generate_line_from_pack(packs.packs[i], fullLine, target_width-cover_width);
          heightSum += parseFloat(line.find('img').css('height'));
					head2.append( line );
          local_data.current_line_cursor = packs.packs[i][packs.packs[i].length-1] + 1;
        }

        try {
          if (packs.packs.length >= current_coverRows) {
            var margin_h = 5;
            //Fine tuning the height/width of the first lines
            var scale_1 = ( 0.0 + target_width + margin_h * (target_width-cover_width) / heightSum - local_data.options.margin ) / ( cover_width + (cover_height * (target_width-cover_width) / heightSum ) );
            var scale_2 = ( 0.0 + target_width - local_data.options.margin - margin_h * cover_width / cover_height ) / ( (target_width-cover_width) + heightSum * cover_width / cover_height );

            head1.find('img').each(function(){
              $(this).css('height', parseFloat($(this).css('height')) * scale_1);
              $(this).css('width', parseFloat($(this).css('width')) * scale_1);
            });

            head2.find('img').each(function(){
              $(this).css('height', parseFloat($(this).css('height')) * scale_2);
              $(this).css('width', parseFloat($(this).css('width')) * scale_2);
            });
          }
        } catch(e){}


        destination_div.each(function(){
          $(this).append( head );
					$(this).resize();
        });
				
        local_data.current_line_number++;
      }

      packs = pack_images(local_data.current_line_cursor, local_data.options.width, [ local_data.options.coverIndex ]);

      $.each(packs.packs, function(idx, pack) {
        //console.log("idx:"+idx+" - len:"+(packs.packs.length-1));
        if (idx < packs.packs.length-1 || !packs.hasMore)
        {
          var fullLine = ((idx<packs.packs.length-1)||!packs.lastNotComplete);
          var line = generate_line_from_pack(pack, fullLine, local_data.options.width);
          destination_div.each(function(){
            $(this).append( line );
						$(this).resize();
          });
          local_data.current_line_cursor = pack[pack.length-1] + 1;
          local_data.current_line_number++;
        }
      });

      if (!packs.hasMore)
        local_data.options.loaded();
    };

    //formats a line
    var generate_line_from_pack = function(pack, full_line, target_width) {
      //console.log(pack);

      var line_width = 0.0;
      $.each(pack, function(idx, i) {
        line_width += local_data.all_img[i].width * 1.0 * local_data.options.max_height / local_data.all_img[i].height;
      });

      //if the line is not complete, then display it at max_height
      var scale = 1.0;
      //console.log(full_line);
      if (full_line)
        scale = 1.0 * (target_width - (pack.length-1)*local_data.options.margin ) / line_width;

      var line = $("<div></div>");
      line.css('width', target_width + local_data.options.widthMargin);

      var real_line_width = 0;
      $.each(pack, function(idx, i) {
        var new_width = Math.round(local_data.all_img[i].width * local_data.options.max_height * scale / local_data.all_img[i].height);
        real_line_width += new_width;
        //fixing the width of the last image to fit exactly the requested width
        if (idx == pack.length-1 && full_line)
          new_width -= real_line_width - (target_width - (pack.length-1)*local_data.options.margin);
        local_data.all_img[i].obj.css("width", new_width).css("height", local_data.options.max_height * scale);
        line.append( local_data.all_img[i].obj );
        local_data.all_img[i].line = local_data.current_line_number;
      });

      return(line);
    };


    //add a picture at the end of the gallery
    var append = function(img){
	  var url = img.image;
	  if (img.image == null || img.image == '') {
		if (img.thumb != null) {
			url = img.thumb;
		} else {
			url = "/img/picture_placeholder.png";	
		}
	  }
      var idx = local_data.all_img.length;

      local_data.options.loading();

      var neobj = $("<img></img>");
      neobj.load(function(){
            var local_idx = idx;
            $('body').append(this);
            var dim = $(this).getHiddenDimensions();
            $(this).detach();
            local_data.all_img[local_idx].loaded = true;
            local_data.all_img[local_idx].height = dim.height;
            local_data.all_img[local_idx].width = dim.width;
            append_ready();
          });
      //if (img.thumb != null) url = img.thumb;
      local_data.all_img[idx] = {
          loaded: false,
          height: null,
          width: null,
          line: null,
          requested: img,
          obj: neobj
        };
      neobj.attr("src", url);
      var this_obj = local_data.all_img[idx];
      local_data.all_img[idx].obj.click(function(e){
          if ($(this).hasClass('noclick')) {
            $(this).removeClass('noclick');
          } else {
            var m=this_obj;
            local_data.options.onclick(idx,m,e);
          }
        });
      if (local_data.options.editable) {
        local_data.all_img[idx].obj.draggable({
            scroll: false,
            revert: true,
            revertDuration: 500,
            start: function(event, ui) {
                      $('.ui-draggable').css({ top: '', left: ''});
                      $(this).draggable( "option", "revert", true );
                      $(this).addClass('noclick');
                      $(this).css('z-index', 900);
                    },
            stop: function (event, ui) {
                      $('.dragging').removeClass('dragging');
                      $('.sameline-dragging').removeClass('sameline-dragging');
                      $(this).css('z-index', 0);
                    }
        });
        over_droppable = null;
        local_data.all_img[idx].obj.droppable({
            drop: function(ev, ui) {
                      $(ui.draggable).draggable( "option", "revert", false );
                      $(ui.draggable).css({ top: '', left: ''});
                      $(this).removeClass('dragging');
                      var dst = $(this).attr('src');
                      var src = ui.draggable.attr('src');
                      var dst_obj = $(this);
                      $.each(local_data.all_img, function(idx, elt) {
                        if (dst_obj[0] == elt.obj[0])
                          dst_idx = idx;
                        if (ui.draggable[0] == elt.obj[0])
                          src_idx = idx;
                      });

                      if (!local_data.options.coverForceFirst && dst_idx == local_data.options.coverIndex) {
                        local_data.options.coverIndex = src_idx;
                        redraw_from_line(0);
                      }
                      else
                        move(src_idx, dst_idx);
                    },
            over: function(event, ui) {
                      if ($(this).parent()[0] == ui.draggable.parent()[0]) {
                        var list = $(this).parent().children();
                        var e = list.first();
                        var found_before = false;
                        var between = false;
                        for (var i=0; i<list.length && list[i] != ui.draggable[0]; i++) {
                          if (list[i] == this){
                            between = true;
                            found_before = true;
                            over_droppable = this;
                            //console.log('adding class : '+$(over_droppable).attr('src'));
                          }
                          if (between)
                            $(list[i]).addClass('sameline-dragging');
                          else
                            $(list[i]).removeClass('sameline-dragging');
                        }
                        if (!found_before && list.length>i+2 && list[i+1] != this)
                           $(this).addClass('dragging');
                      }
                      else
                        $(this).addClass('dragging');
                    },
            out: function(event, ui) {
                      if (over_droppable == this) {
                        //console.log('remove class everywhere : '+$(over_droppable).attr('src'));
                        $('.sameline-dragging').removeClass('sameline-dragging');
                      }
                      $(this).removeClass('dragging');
                      over_droppable = null;
                    }
          });
      }
    };


    //Appends a list of images at the end of the gallery
    var append_list = function(list) {
      $.each(list, function(idx, img){
        append(img);
      });
      redraw_from_line(0);
    };

    var append_redraw = function(elt) {
      append(elt);
      redraw_from_line(0);
    };

    var redraw_from_line = function(line_number) {
      local_data.current_line_cursor = null;
      local_data.current_line_number = line_number;

      $.each(local_data.all_img, function(i, img){
        if (img.line >= local_data.current_line_number && (local_data.current_line_cursor == null || i < local_data.current_line_cursor))
          local_data.current_line_cursor = i;
      });

      //console.log('local_data.current_line_cursor :'+local_data.current_line_cursor);

      $.each(destination_div.children(), function(i, div){
        if (i >= local_data.current_line_number)
          $(div).detach();
      });

      append_ready();
    };

    //Remove only 1 picture from the gallery
    var remove_at = function(idx) {

      local_data.current_line_cursor = null;
      local_data.current_line_number = local_data.all_img[idx].line;

      //reset everything at the beginning of the line to rebuild
      $.each(local_data.all_img, function(i, img){
        if (local_data.current_line_cursor == null && img.line >= local_data.current_line_number)
          local_data.current_line_cursor = i;
      });

      $.each(destination_div.children(), function(i, div){
        if (local_data.current_line_number <= i)
          $(div).detach();
      });

      local_data.trashed_img.push(local_data.all_img.splice(idx,1));
      append_ready();
    };

		//Removes 1 picture found by its url (the first is taken)
    var remove_url = function(url) {
      remove_at(find_by_url(url));
    };

    var remove_obj = function(img) {
			$.each(local_data.all_img, function(idx, elt) {
        if (elt != null && img[0] == $(elt.obj)[0]) {
					remove_at(idx);
				}
      });
    };

    //Remove only 1 picture from the gallery
    var move = function(src,dst) {

      local_data.current_line_cursor = null;
      local_data.current_line_number = Math.min(local_data.all_img[src].line, local_data.all_img[dst].line);

      //reset everything at the beginning of the line to rebuild
      $.each(local_data.all_img, function(i, img){
        if (local_data.current_line_cursor == null && img.line >= local_data.current_line_number)
          local_data.current_line_cursor = i;
      });

      $.each(destination_div.children(), function(i, div){
        if (local_data.current_line_number <= i)
          $(div).detach();
      });
      if (src > dst) {
        var obj = local_data.all_img.splice(src,1)[0];
        local_data.all_img.splice(dst,0,obj);
      } else {
        var obj = local_data.all_img.splice(src,1)[0];
        local_data.all_img.splice(dst-1,0,obj);
      }

      append_ready();
    };

		var find_by_url = function(url) {
		  var fnidx = null;
			$.each(local_data.all_img, function(idx, elt) {
        if (url == $(elt.obj).attr('src'))
					fn_idx = idx;
      });
      return(fn_idx);
		};

    //Removes all pictures from the gallery
    var clean = function(){
      local_data.current_line_cursor = 0;
      local_data.current_line_number = 0;

      $.each(destination_div.children(), function(i, div){
        $(div).detach();
      });

      local_data.all_img.splice(0,local_data.all_img.length);
    };

    //returns the list of pictures
    var list = function(){
      return($.map(local_data.all_img, function(e,idx){return e.requested;}));
    };

    //Fetching stored variables
    var local_data = $(this).data('neat_gallery');

    if (!local_data) {
      local_data = {};
      local_data.current_line_cursor = 0;
      local_data.current_line_number = 0;
      local_data.options = defaults;
      local_data.all_img = [];
      local_data.trashed_img = [];
      $(this).data('neat_gallery', local_data);
    }

    if (argument == "append") return append_redraw;
    if (argument == "append_list") return append_list;
    if (argument == "remove_at") return remove_at;
    if (argument == "remove_url") return remove_url;
    if (argument == "remove_obj") return remove_obj;
    if (argument == "clean") return clean;
    if (argument == "list") return list;
    if (typeof argument === 'object' || !argument) {
      var argument_copy = jQuery.extend(true, {}, argument);
      local_data.options = $.extend(local_data.options, argument_copy);

      //forcing the favorite image as the first
      if (local_data.options.cover && local_data.options.coverForceFirst && local_data.options.coverIndex > 0) {
        var cover = local_data.options.source.splice(local_data.options.coverIndex, 1);
        local_data.options.source.unshift(cover[0]);
        local_data.options.coverIndex = 0;
      }

      return this.each(function() {
          local_data.options.flag_isLoading = true;
          $.each(local_data.options.source, function(idx, img){
              append(img);
            });
          local_data.options.flag_isLoading = false;
          if (local_data.all_img.length > 0) append_ready();
          if (local_data.options.source == null || local_data.options.source.length == 0)
            local_data.options.loaded();
        });
    }
 };

})(jQuery);
