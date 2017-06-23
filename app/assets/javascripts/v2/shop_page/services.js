$(document).ready(function()
{
  $('.details').click(function(){

    $(this).closest('.product').find('.description').toggle(function(){
      if($(this).hasClass('closed'))
      {
        $(this).slideDown('slow');
        $(this).closest('.product').find('.details').html('Hide details');
        $(this).removeClass('closed');
      }
      else
      {
        $(this).slideUp('slow');
        $(this).closest('.product').find('.details').html('View details');
        $(this).addClass('closed');
      }
    });
  });

  $('.load_more_button').click(function ()
    {
      var category = $(this).closest('.product_list').find('.category').html();

      if ($(this).hasClass('more'))
      {
        $(this).closest('.product_list').find('.hided').hide();
        $(this).removeClass('more');
        $(this).html('Show more ' + category);
      }
      else
      {
        $(this).closest('.product_list').find('.hided').show();
        $(this).addClass('more');
        $(this).html('Show less ' + category);
      }
    });


  //Force checkout if user is not logged

});