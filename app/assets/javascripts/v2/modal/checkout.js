// DiveboardCheckoutCore gestion des appels reseaux au checkout

function DiveboardCheckoutCore() {
}


DiveboardCheckoutCore.checkout_basket = null;
DiveboardCheckoutCore.shop_id = null;
DiveboardCheckoutCore.current_id = null;
DiveboardCheckoutCore.add = function(data) {
  var data_to_send = {
    elt: JSON.stringify(data),
    'authenticity_token': auth_token
  }
  //Pushing to basket
  $.ajax({
    url: "/api/basket/add",
    type: "POST",
    data: data_to_send,
    success: function(response){
    	DiveboardCheckoutCore.updateBasket(response);
    	DiveboardCheckoutCore.current_id = response.basket_item_id;
    	DiveboardCheckoutModal.updateUI();
    	DiveboardCheckoutHeader.updateUI();
    	DiveboardCheckoutView.updateUI();
    },
    error: function() {
    }
  });
}

DiveboardCheckoutCore.update = function(data, itemId) {
	if (itemId == null) {
		return;
	}
  var data_to_send = {
    elt: JSON.stringify(data),
    'authenticity_token': auth_token
  }

	data_to_send.id = itemId;
  //Pushing to basket
  $.ajax({
    url: "/api/basket/update",
    type: "POST",
    data: data_to_send,
    success: function(response) {
    	DiveboardCheckoutCore.updateBasket(response);
    	DiveboardCheckoutCore.current_id = response.basket_item_id;
    	DiveboardCheckoutHeader.updateUI();
    	DiveboardCheckoutView.updateUI();
	    DiveboardCheckoutModal.updateUI();
    },
    error: function(){
    }
  });
}

DiveboardCheckoutCore.delete = function(itemId) {
	$.ajax({
    url: "/api/basket/remove",
    type: "POST",
    data: {
      id: itemId,
      'authenticity_token': auth_token
    },
    success: function(response) {
    	DiveboardCheckoutCore.updateBasket(response);
    	DiveboardCheckoutCore.current_id = response.basket_item_id;
    	DiveboardCheckoutModal.updateUI();
    	DiveboardCheckoutHeader.updateUI();
    	DiveboardCheckoutView.updateUI();
    },
    error: function(){
    }
  });
}

DiveboardCheckoutCore.get = function() {
	 $.ajax({
    url: "/api/basket/get",
    type: "GET",
    success: function(response) {
    	DiveboardCheckoutCore.updateBasket(response);
    	DiveboardCheckoutModal.updateUI();
    	DiveboardCheckoutHeader.updateUI();
    },
    error: function(){
    }
  });
}
DiveboardCheckoutCore.getBasket = function() {
  if (DiveboardCheckoutCore.checkout_basket != null) {
	  return DiveboardCheckoutCore.checkout_basket[DiveboardCheckoutCore.shop_id];
	}
	return null;
}
DiveboardCheckoutCore.getBaskets = function() {
  if (DiveboardCheckoutCore.checkout_basket != null) {
	  return DiveboardCheckoutCore.checkout_basket;
	}
	return null;
}
DiveboardCheckoutCore.updateBasket = function(basket) {
  if (basket != null && basket['success'] == true) {
	  DiveboardCheckoutCore.checkout_basket = basket['result'];
	}
	return null;
}
DiveboardCheckoutCore.getBasketItem = function(itemId) {
  if (DiveboardCheckoutCore.getBasket() != undefined) {
	  var items = DiveboardCheckoutCore.getBasket()['basket_items'];
		for (i = 0; i < items.length; i++) {
			var x = items[i];
	    if (itemId == x.id) {
				return x;
	    }
		}
	}
	return null;
}

//Gestion de la modal checkout et appel au Core pour les interaction serveur
function DiveboardCheckoutModal() {
}

DiveboardCheckoutModal.product= null;
DiveboardCheckoutModal.getDate = function() {
	//TODO getDate from cookie to pre-full the date input
}

DiveboardCheckoutModal.saveDate = function() {
	//TODO saveDate in cookie to pre-full the date input
}

DiveboardCheckoutModal.changeDateTypeUI = function(obj) {
  var selected = obj.val();
	DiveboardCheckoutModal.product.details.date_type = selected;
  var form = obj.closest('.date');
  form.find(".form_date_type").hide();
  form.find(".form_date_type_"+selected).show();
  DiveboardCheckoutCore.update(DiveboardCheckoutModal.product, DiveboardCheckoutCore.current_id);
}
DiveboardCheckoutModal.changeDateUI = function(dateText, obj) {
	if (obj.hasClass('date_from')) {
		DiveboardCheckoutModal.product.details.date_from = dateText;
	}
	else if (obj.hasClass('date_to')) {
		DiveboardCheckoutModal.product.details.date_to = dateText;
	}
	else if (obj.hasClass('date_at')) {
		DiveboardCheckoutModal.product.details.date_at = dateText;
	}
	DiveboardCheckoutCore.update(DiveboardCheckoutModal.product, DiveboardCheckoutCore.current_id);
}

DiveboardCheckoutModal.changeItemNumber = function(obj) {
	DiveboardCheckoutModal.product.quantity = obj.val();
	DiveboardCheckoutCore.update(DiveboardCheckoutModal.product, DiveboardCheckoutCore.current_id);
	// $('.item .price .total').html('$' + (product_price * $(this).val()));
}

DiveboardCheckoutModal.changeComment = function(obj) {
	DiveboardCheckoutModal.product.details.comment = obj.val();
	DiveboardCheckoutCore.update(DiveboardCheckoutModal.product, DiveboardCheckoutCore.current_id);
	// $('.item .price .total').html('$' + (product_price * $(this).val()));
}
DiveboardCheckoutModal.checkoutNowUI = function() {
	//TODO redirect on the checkout page
}
DiveboardCheckoutModal.continueShopUI = function() {
	// Only a close make by LightModal
}
DiveboardCheckoutModal.cancelUI = function() {
	DiveboardCheckoutCore.delete(DiveboardCheckoutCore.current_id);
	DiveboardCheckoutModal.product = null;
	checkout_modal.close();
}

DiveboardCheckoutModal.updateUI = function() {
	if($('#checkout_modal').length!=0){
		//var item = DiveboardCheckoutCore.getBasketItem(DiveboardCheckoutCore.current_id);
		var unit = parseFloat($('#checkout_modal .item .price .one').html().replace(DiveboardCheckoutModal.symbol,''));
		var mult = parseFloat($("#checkout_modal .item .number_div  input[name^='howmuch']").val());
		var sub = parseFloat($('#checkout_modal .total_checkout .count .price .sub').first().html().replace(DiveboardCheckoutModal.symbol,''));
		if (DiveboardCheckoutModal.symbol_first) {
			$('#checkout_modal .item .price .total').html(DiveboardCheckoutModal.symbol + parseFloat((unit*mult).toFixed(2)));
		}else{
				$("#checkout_modal .primary.total").first().html(parseFloat((unit*mult+sub).toFixed(2))+DiveboardCheckoutModal.symbol);
		}
		
		var baskets = DiveboardCheckoutCore.getBaskets();
		var basket = baskets[DiveboardCheckoutModal.shop_id];
		/*if (item != null) {
			$('#checkout_modal .item .price .total').html('$' + item.line_price_after_tax_in_string);
		}*/
		if (basket != null) {
		  $('#checkout_modal .total_checkout .count .price .sub').html(basket.total_formated);
		  $('#checkout_modal .total_checkout .count .price .discount_amount').html('$' + '0');
		  $('#checkout_modal .total_checkout .count .price .total').html(basket.total_formated);
		}
	}
}

DiveboardCheckoutModal.initModalUI = function(shop_data, product_name, product_price, init_date, product) {
  var today = Date.now();
  var min_date = today + Math.ceil(shop_data.delay_bookings/24+1)*24*3600*1000;
  var max_date = today + 365*24*3600*1000;
  var symbol = shop_data.currency_symbol;
  var symbol_first = shop_data.currency_first;
  DiveboardCheckoutModal.symbol=symbol;
  DiveboardCheckoutModal.symbol_first=symbol_first;
  if(symbol_first){
  	$('#checkout_modal .item .price .one').html(symbol + product_price);
  	$('#checkout_modal .item .price .total').html(symbol + product_price);
  }
  else{
  	$('#checkout_modal .item .price .one').html(product_price+symbol);
  	$('#checkout_modal .item .price .total').html(product_price+symbol);
  }
 
  $('#checkout_modal .item .product .shop_title').html(shop_data['name']);
  $('#checkout_modal .item .product .shop_product').html(product_name);
  $.datepicker.setDefaults($.datepicker.regional[$("html").attr("lang") || 'en']);
	$(".date input[name=date_type]").on('change', function(){
		DiveboardCheckoutModal.changeDateTypeUI($(this));
  });
  $(".item input[name='howmuch']").on('keyup mouseup', function () {
		DiveboardCheckoutModal.changeItemNumber($(this));
  });
  $(".comment textarea").on('change', function () {
		DiveboardCheckoutModal.changeComment($(this));
  });
  $(".link .remove-item").click(function () {
		DiveboardCheckoutModal.cancelUI();
  });
  $("#checkout_modal .date .date_picker").val(init_date);
  if (product == null) {
	  $("#checkout_modal .item input[name='howmuch']").val(1);
	  $("#checkout_modal .date .date_picker").datepicker({
	    dateFormat: 'yy-mm-dd',
	    changeMonth: true,
	    changeYear: true,
	    minDate: new Date(min_date),
	    maxDate: new Date(max_date),
	    gotoCurrent: true,
	    onClose: function(dateText, inst) {
	    	console.log(dateText);
	      if (dateText.match(/[0-9]{4}-[0-9]{2}-[0-9]{2}/)){
	        DiveboardCheckoutModal.changeDateUI(dateText, $(this));
	      }
	    }
	  });
	} 
	else {
		$("#checkout_modal .item input[name='howmuch']").val(product.quantity);
			  $("#checkout_modal .date .date_picker").datepicker({
	    dateFormat: 'yy-mm-dd',
	    changeMonth: true,
	    changeYear: true,
	    minDate: new Date(min_date),
	    maxDate: new Date(max_date),
	    gotoCurrent: true,
	    onClose: function(dateText, inst) {
	    	console.log(dateText);
	      if (dateText.match(/[0-9]{4}-[0-9]{2}-[0-9]{2}/)){
	        DiveboardCheckoutModal.changeDateUI(dateText, $(this));
	      }
	    }
	  });
		if(symbol_first){
			$('#checkout_modal .item .price .total').html(symbol + product.quantity * product_price);
		}
		else{
			$('#checkout_modal .item .price .total').html(product.quantity * product_price+ symbol);
		}
		if (product.details.date_type != "one") {
			$(".date .form_date_type").hide();
  		$(".date .form_date_type_period").show();

  		$(".date .date_to").val(product.details.date_to);
  		$(".date .date_from").val(product.details.date_from);
  		$(".comment textarea").val(product.details.comment);
		}
	}
  DiveboardCheckoutModal.updateUI();
}

DiveboardCheckoutModal.initUI = function() {
  $('.book_button').click(function()
  {
    ga('send', 'event', 'shop', 'book_now');

    var shop_data = $(this).closest(".shop_data").data('shop');
	var product_name = $(this).attr('product_name');
  	var product_price = $(this).attr('product_price');
  	var product_id = $(this).attr('product_id');
    checkout_modal.display('checkout');
  	DiveboardCheckoutModal.product = {
	    id: product_id,
	    quantity: 1
	  };
  	var today = Date.now();
  	var min_date = today + Math.ceil(shop_data.delay_bookings/24+1)*24*3600*1000;
  	var init = new Date(min_date);
  	var curr_date = init.getDate();
		var curr_month = init.getMonth() + 1;
		var curr_year = init.getFullYear();
    DiveboardCheckoutModal.product.details = {
      date_type: "one"
    };
    DiveboardCheckoutModal.product.details.date_at = curr_year + "-" + curr_month + "-" + curr_date;
		DiveboardCheckoutModal.product.details.divers = [];
		DiveboardCheckoutModal.shop_id = shop_data.id;
		DiveboardCheckoutCore.shop_id = shop_data.id;
		DiveboardCheckoutCore.add(DiveboardCheckoutModal.product);
    DiveboardCheckoutModal.initModalUI(shop_data, product_name, product_price, DiveboardCheckoutModal.product.details.date_at, null);
  });
}

//Gestion du header checkout et appel au Core pour les interaction serveur
function DiveboardCheckoutHeader() {
}
DiveboardCheckoutHeader.initUI = function() {
	$('.basket #basket-ic').click(function() {
		DiveboardCheckoutHeader.toggleCheckout();
	});
	DiveboardCheckoutHeader.updateUI();
}
DiveboardCheckoutHeader.updateUI = function() {
	var baskets = DiveboardCheckoutCore.getBaskets();
	var nb_items =0;
	var total = 0;
	var array_item = [];
	var html = "";
	if(baskets!=undefined){
		$.each(baskets, function(index,basket){
			if (basket != null) {
				var tmp_shop = basket.shop_name;
				nb_items += basket.nb_items;
				//total += parseFloat(basket.total_formated.substring(1));
				if (basket.basket_items != null) {
				    var basket_items_tmpl = tmpl("header_basket_item_tmpl");
				    for ( var i = 0; i < basket.basket_items.length; i++ ) {
				    	var tmp = basket.basket_items[i];
				    	if(tmp_shop!=null){
				    		tmp.shop = basket.shop_name;
				    	}
				    	if(i== basket.basket_items.length-1){
				    		tmp.total = basket.total_formated;
				    		tmp.firstId=(basket.basket_items[0]).id;
				    	}
				     	html += basket_items_tmpl( {item: tmp} );
				     	tmp_shop=null;

				     // array_item.push(basket.basket_items[i]);
				    }

				}


			}	
		});
		$('.basket #basket-ic .item_count').html(nb_items);
		//$('.basket .basket_content .total .price').html(total);
		$('.basket .basket_content .items').html(html);
		$('.basket .basket_content .items img').click(function() {
			DiveboardCheckoutHeader.deleteItem($(this));
		});
	}
	if (baskets != undefined && nb_items > 0) {
		$('#header .basket').show();
	} else {
		$('#header .basket').hide();
	}


}

DiveboardCheckoutHeader.deleteItem = function(obj) {
	var id = obj.data('item-id');
	DiveboardCheckoutCore.delete(id);
}

DiveboardCheckoutHeader.toggleCheckout = function() {
	if ($('.basket #basket-ic').hasClass('open')) {
		$('.basket .basket_content').hide();
		$('.basket #basket-ic').removeClass('open')
	} else {
		$('.basket .basket_content').show();
		$('.basket #basket-ic').addClass('open')
	}
}


function DiveboardCheckoutView() {
}
DiveboardCheckoutView.deleteItem = function(obj) {
	var id = obj.closest('.item').data('basket-item-id');
	//alert(id);
	DiveboardCheckoutCore.delete(id);
}
DiveboardCheckoutView.changeItemNumber = function(obj) {
	var itemId = obj.closest('.item').data('basket-item-id');
	var productId = obj.closest('.item').data('product-id');
	var product = obj.closest('.item').data('basket-item');
	product.quantity = obj.val();
	DiveboardCheckoutCore.update(product, itemId);
}

DiveboardCheckoutView.openEditModal = function(obj) {
	var itemId = obj.closest('.item').data('basket-item-id');
	var productId = obj.closest('.item').data('product-id');
	var product = obj.closest('.item').data('basket-item');
	var shop_id = obj.closest('.shop-basket').data('shop-id');
	var shop_data = obj.closest('.shop-basket').data('shop');
	DiveboardCheckoutCore.shop_id = shop_id;
	DiveboardCheckoutCore.current_id = itemId;
	var product_name = obj.closest('.item').data('product-name');
  	var product_price = obj.closest('.item').data('product-price');
    checkout_modal.display('checkout');
  	DiveboardCheckoutModal.product = product;
    DiveboardCheckoutModal.initModalUI(shop_data, product_name, product_price, DiveboardCheckoutModal.product.details.date_at, product);
}

DiveboardCheckoutView.confirmPayementClick = function(obj) {
	paypal_basket_start(obj.data('basket-id'));
}
function paypal_basket_start(basket_id) {

  $.ajax({
    url: '/api/paypal/start_basket',
    dataType: 'json',
    type: "GET",
    data: {
      basket_id: basket_id
    },
    success: function(data){
      if (data.success) {
        window.location.replace(data.url);
      }
      else {
        diveboard.alert(I18n.t(["js","global","A technical error occured while initialising the payment process with Paypal."]), data);
        diveboard.unmask_file({"background-color": "#000000"});
      }
    },
    error: function(data) {
      diveboard.alert(I18n.t(["js","global","A technical error occured while initialising the payment process with Paypal."]));
      diveboard.unmask_file({"background-color": "#000000"});
    }
  });
}

DiveboardCheckoutView.initUI = function() {
	$(".checkout-view .item .delete").click(function() {
		DiveboardCheckoutView.deleteItem($(this));
		//$(".content .checkout-view .shop-basket .item[data-basket-item-id='"+$(this).closest('.item').data('basket-item-id')+"']").remove();
		//update
	});
	$(".checkout-view .item .details a").click(function(e) {
		e.preventDefault();
		DiveboardCheckoutView.openEditModal($(this));
	});
	$(".checkout-view .confirm-payement").click(function(e) {
		e.preventDefault();
		DiveboardCheckoutView.confirmPayementClick($(this));
	});
	$(".checkout-view .inquire-shop").click(function(e){
		//$(".checkout-view #modal_"+$(this).data('basket-id')).display('init');
		var alert_modal = new LightModal("modal_"+$(this).data('basket-id'));
        $.ajax({
		    url: '/api/notify_command',
		    dataType: 'json',
		    type: "GET",
		    data: {
		   		shop_id: $(this).data('shop-id'),
		      	user_id: $(this).data('user-id'),
		      	basket_id: $(this).data('basket-id'),
		      	message: "lol",
		      	subject: "test"
		    },
		    success: function(data){
		      if (data.success) {
		      }
		      else {
		      }
		    },
		    error: function(data) {
		    }
  		});
  		        alert_modal.display();

	});
	$(".checkout-view .item input[name='howmuch']").on('keyup mouseup', function () {
		DiveboardCheckoutView.changeItemNumber($(this));
  });
}
DiveboardCheckoutView.updateUI = function() {
	var obj = $('#item-' + DiveboardCheckoutCore.current_id);
	var shop_id = obj.closest('.shop-basket').data('shop-id');
	var shop_data = obj.closest('.shop-basket').data('shop');
	DiveboardCheckoutCore.shop_id = shop_id;
	var basket = DiveboardCheckoutCore.getBasket();
	var item = DiveboardCheckoutCore.getBasketItem(DiveboardCheckoutCore.current_id);
	if (item != null) {
		$('.checkout-view #item-' + DiveboardCheckoutCore.current_id +' .price .total').html(item.line_price_after_tax_in_string);
	}
	else{
		if(basket == null){
			var baskets = DiveboardCheckoutCore.getBaskets();
			if(jQuery.isEmptyObject(baskets) && window.location.pathname=="/pro/checkout"){
				window.location="/?redirect=";
			}
			else{
				$('.checkout-view #item-' + DiveboardCheckoutCore.current_id).parent().parent().remove();
			}
		}else{
			$('.checkout-view #item-' + DiveboardCheckoutCore.current_id).remove();
		}
	}
	if (basket != null) {
		if(basket.total_formated!=0){
	  		$('.checkout-view .total-basket #'+basket.id).html(basket.total_formated + shop_data['currency']);
		}
	}
}

$(document).ready(function() {
	DiveboardCheckoutHeader.initUI();
	DiveboardCheckoutView.initUI();
	if (window.location.hash) {
            setTimeout(function() {
                $('html, body').scrollTop(0).show();
                $('html, body').animate({
                    scrollTop: $(window.location.hash).offset().top-50
                    }, 500)
            }, 0);
        }
})