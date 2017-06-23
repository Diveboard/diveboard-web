class V2::TestAreaPagesController < V2::ApplicationController
	layout nil
	def index
		render :index, :layout => false
	end
end
