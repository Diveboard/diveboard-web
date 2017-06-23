$(document).ready(function(){
  //copy the shops from the page into the modal
  var shops_tag = $('#shops .container').html();
  $('#shopsModal .modal_content .container').append(shops_tag);
  $('#shopsModal .modal_content .container').append($('#shopsModal .load_more_button'));

  //copy the reviews from the page into the modal
  var reviews_tag = $('#reviews .container').html();
  $('#reviewsModal .modal_content .container').append(reviews_tag);
  $('#reviewsModal .modal_content .container').append($('#reviewsModal .load_more_button'));
  
  $('#shops .see_all_button').click(function(){
  });

  $('#shopsModal .load_more_button').click(function(){
    moreShops();
  });

  $('#reviewsModal .load_more_button').click(function(){
    moreReviews();
  });

  var shops_container = $('#shops_modal .container');
  var reviews_container = $('#reviews_modal .container');

  shops_container.scroll(moreShops);
  $('#reviewsModal .modal_content').scroll(moreReviews);

  shops_container.infinitescroll({
    debug: true,
    bufferPx: 900,
    animate: false,
    navSelector  : '#shops-page-nav',    // selector for the paged navigation
    nextSelector : '#shops-page-nav a',  // selector for the NEXT link (to page 2)
    itemSelector : '.shop',     // selector for all items you'll retrieve
    loading: {
        finishedMsg: 'No more shops to load.',
        img: "/img/transparent_loader.gif",
        speed: 0,
        msgText: "Loading more shops..."
      }
    },

    function( newElements ) {
      // add the load more button at the end of the container
      $('#shopsModal .modal_content .container').append($('#shopsModal .load_more_button'));
      $('#shopsModal .load_more_button').css('display', 'block');

    }
  );

  reviews_container.infinitescroll({
    debug: false,
    bufferPx: 900,
    animate: false,
    navSelector  : '#reviews-page-nav',    // selector for the paged navigation
    nextSelector : '#reviews-page-nav a',  // selector for the NEXT link (to page 2)
    itemSelector : '.review',     // selector for all items you'll retrieve
    loading: {
        finishedMsg: 'No more reviews to load.',
        img: "/img/transparent_loader.gif",
        speed: 0,
        msgText: "Loading more reviews..."
      }
    },

    function( newElements ) {
      // add the load more button at the end of the container
      $('#reviewsModal .modal_content .container').append($('#reviewsModal .load_more_button'));
      $('#reviewsModal .load_more_button').css('display', 'block');
    }
  );

});

function moreShops(){
  $('#shopsModal .load_more_button').css('display', 'none');
  $('#shopsModal .modal_content .container').infinitescroll('scroll');
}

function moreReviews(){
  console.log("SCROLLING REVIEWS");
  $('#reviewsModal .load_more_button').css('display', 'none');
  $('#reviewsModal .modal_content .container').infinitescroll('scroll');
}