$(document).ready(function()
{
  var width = $(window).width();
  var species = $('.species');

  tip = {
    width: 19,
    height: 10
  };

  var length = species.length;
  var i = 0;

  while (i < length)
  {
    var name = $(species[i]).attr('alt');
    name = name.charAt(0).toUpperCase() + name.slice(1);

    $('#species' + i).qtip({
      content: {
        text: name
      },
      position: {
        my: 'bottom center',
        at: 'top center'
      },
      style: {
        classes: 'qtip-diveboard text-center',
        tip: tip
      }
    });
    i++;
  }
});