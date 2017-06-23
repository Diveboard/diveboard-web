$(document).ready(function(){
  //copy the reviews from the page into the modal
  var reviews_tag = $('#shop_reviews .container').html();
  $('#reviewsModal .modal_content .container').append(reviews_tag);
  $('#reviewsModal .modal_content .container').append($('#reviewsModal .load_more_button'));
  
  $('#reviewsModal .load_more_button').click(function(){
    moreReviews();
  });

  var reviews_container = $('#reviews_modal .container');

  $('#reviewsModal .modal_content').scroll(moreReviews);

  reviews_container.infinitescroll({
    debug: true,
    bufferPx: 900,
    animate: false,
    navSelector  : '#reviews-page-nav',    // selector for the paged navigation
    nextSelector : '#reviews-page-nav a',  // selector for the NEXT link (to page 2)
    itemSelector : '.shop_review',     // selector for all items you'll retrieve
    loading: {
        finishedMsg: 'No more reviews to load.',
        img: "/img/transparent_loader.gif",
        speed: 0,
        msgText: "Loading more reviews..."
      }
    },

    function( newElements ) {
      // add the load more button at the end of the container
      console.log(newElements);
      $('#reviewsModal .modal_content .container').append($('#reviewsModal .load_more_button'));
      $('#reviewsModal .load_more_button').css('display', 'block');
    }
  );

});

function moreReviews(){
  console.log("SCROLLING REVIEWS");
  $('#reviewsModal .load_more_button').css('display', 'none');
  $('#reviewsModal .modal_content .container').infinitescroll('scroll');
}