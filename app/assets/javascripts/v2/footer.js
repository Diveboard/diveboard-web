//TODO replace messages and pop ups

$().ready(function() {
  $('#newsletter_subsribe').click(subscribe_newsletter);
  $('.languages').on('change', function (e) {
    var optionSelected = $("option:selected", this);
    var host = optionSelected.attr('data-href-hostname');
    window.location.host = host;
  });
});

function subscribe_newsletter()
{
  email = $('#newsletter_email').val().trim();
  if (email.length == 0)
  {
    $('#newsletter_email').qtip({
      content: {
        text: 'Invalid email'
      },
      position: {
        my: 'bottom center',
        at: 'top center'
      },
      style: {
        classes: 'qtip-diveboard qtip-divered'
      },
      show: {
        ready: true
      },
      hide: {
        event: 'unfocus',
        inactive: 4000
      }
    });
    return ;
  }
  $.ajax({
    url: '/api/v2/newsletter_subscribe/' + email,
    dataType: 'json'
  }).done(function(result) {
    if (result.success == false)
    {
      $('#newsletter_email').qtip({
        content: {
          text: 'Invalid email'
        },
        position: {
          my: 'bottom center',
          at: 'top center'
        },
        style: {
          classes: 'qtip-diveboard qtip-divered'
        },
        show: {
          ready: true
        },
        hide: {
          event: 'unfocus',
          inactive: 4000
        }
      });
    }
    else
    {
      $('#newsletter_email').val('');
      $('#newsletter_email').qtip({
        content: {
          text: 'You are now subscribed to Diveboard\'s newsletter on ' + result.email + '!'
        },
        position: {
          my: 'bottom center',
          at: 'top center'
        },
        style: {
          classes: 'qtip-diveboard qtip-divegreen'
        },
        show: {
          ready: true
        },
        hide: {
          event: 'unfocus',
          inactive: 4000
        }
      });
    }
  });
}