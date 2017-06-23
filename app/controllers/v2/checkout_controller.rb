class V2::CheckoutController < V2::ApplicationController
	def index
		begin
			if !@user
				signup_popup_force
				@checkout_baskets = []
				render :layout => 'v2blank'
			end
			@checkout_baskets = @baskets.values
		rescue
			signup_popup_force
			@checkout_baskets = []
			render :layout => 'v2blank'
		end
	end

	def success
		@checkout_basket = Basket.fromshake(params[:vanity_url])
	end
end
