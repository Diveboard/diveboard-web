function LightModal(elem_id, initial_id, context)
{
  this.elemId = elem_id;
  this.context = context;
  this.initModalId = initial_id;
  this.trigger = [];

  this.trigger['close'] = this.close;
  this.trigger['reload'] = this.reload;
}

LightModal.prototype.close = function(elem)
{
    $('#' + elem).removeClass('active_modal');
    $("body").css('overflow', 'auto');
}

LightModal.prototype.reload = function(elem)
{
    $('#' + elem).removeClass('active_modal');
    location.reload();
}

LightModal.prototype.display = function(modal_id, context)
{
  console.log("view login");
  if (context != undefined)
    this.context = context;
  var to_display = (modal_id == undefined) ? this.initModalId : modal_id;
  var _this = this;
  $("body").css('overflow', 'hidden');
  $('#' + this.elemId + ' .modal_content').html($('#' + this.elemId).find("[modal_id='" + to_display + "']").html());
  $('#' + this.elemId + ' .modal_content').attr('class', 'modal_content');
  if ($('#' + this.elemId).find("[modal_id='" + to_display + "']").attr('modal_class') != undefined)
  {
    $('#' + this.elemId + ' .modal_content').addClass($('#' + this.elemId).find("[modal_id='" + to_display + "']").attr('modal_class'));
  }
  $('#' + this.elemId + ' .modal_content').find('[modal_trigger]').each(function(key, value)
    {
      if ($(value).attr('modal_trigger') == 'close')
      {
        $(value).click(function()
        {
          _this.trigger['close'](_this.elemId);
        });
      }
      if ($(value).attr('modal_trigger') == 'reload')
      {
        $(value).click(function()
        {
          _this.trigger['reload'](_this.elemId);
        });
      }
      $(value).click(function()
      {
        _this.trigger[$(value).attr('modal_trigger')]();
      });
    });
  $('#' + this.elemId).addClass('active_modal');
  this._lightModalWinResize(this.elemId);
  $(window).resize(function()
    {
      _this._lightModalWinResize(_this.elemId);
    });
};

LightModal.prototype._lightModalWinResize = function(elemId)
{
  var top = ($(window).height() / 2) - ($('#' + elemId + ' .modal_content').height() / 2);
  if (top < 0)
    top = 0;
  $('#' + elemId + ' .modal_content').css('margin-top', top);
}