class V2::HomepageController < V2::ApplicationController
    def index
      @ga_page_category = "home_v2"
      @page_home = true;
      @page = :home

      if !@user.nil? && !params[:redirect] then
        if @I18n_requested then
          redirect_to @user.fullpermalink(@I18n_requested)
        else
          redirect_to @user.fullpermalink(:preferred)
        end
        return
      end
      #@user = User.find(22733);
      @latest_photos = Picture.find_best_pic(0.9, 1.2).limit(4)
      @latest_photos << Picture.find_best_pic(2.0, 2.4).limit(1).first
      @areas = Area.where("active = 1").order("RAND()").limit(4)
    end

    def suunto
      @ga_page_category = "home_v2"
      @page_home = true;
      @page = :home

    end
end
