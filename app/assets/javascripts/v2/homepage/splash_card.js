$(document).ready(function()
{
  var width = $(window).width();

  var tip = {
    width: 38,
    height: 20
  };

  if (width < 750)
  {
    tip = {
      width: 19,
      height: 10
    };
  }
  var position = {
    my: 'bottom center',
    at: 'top center'
  };
  if (width < 1110)
  {
    position = {
      my: 'bottom left',
      at: 'top right'
    };
  }
  $('#label_discover').qtip({
    content: {
      text: $('#label_discover img').attr('alt')
    },
    position: position,
    style: {
      classes: 'qtip-diveboard',
      tip: tip
    }
  });
  $('#label_book').qtip({
    content: {
      text: $('#label_book img').attr('alt')
    },
    position: {
        my: 'bottom center',
        at: 'top center'
    },
    style: {
      classes: 'qtip-diveboard',
      tip: tip
    }
  });
  $('#label_review').qtip({
    content: {
      text: $('#label_review img').attr('alt')
    },
    position: {
        my: 'bottom center',
        at: 'top center'
    },
    style: {
      classes: 'qtip-diveboard',
      tip: tip
    }
  });
  position = {
    my: 'bottom center',
    at: 'top center'
  };
  if (width < 910)
  {
    position = {
      my: 'bottom right',
      at: 'top left'
    };
  }
  $('#label_share').qtip({
    content: {
      text: $('#label_share img').attr('alt')
    },
    position: position,
    style: {
      classes: 'qtip-diveboard',
      tip: tip
    }
  });
});