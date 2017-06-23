class StaticpagesController < ApplicationController
  before_filter :init_logged_user, :save_origin_url, :signup_popup_hidden #init the graph connection and everyhting user related
  #use the application layout which has header and footer
  layout 'main_layout'

  def tour
    @pagename = "TOUR"
    @ga_page_category = 'tour'
    case params[:what]
      when 'logbook' then what = 1
      when 'sharing' then what = 2
      when 'discovering' then what = 3
      when 'mobile' then what = 4
      when 'price' then what = 5
      else what = 1
    end
    render 'tour', :locals => {:what => what}
  end

  def about
    @pagename ="ABOUT"
    @ga_page_category = 'about'
    if params[:id].nil?
      @menu = 1
    else
      @menu = params[:id]
    end
    render 'about'
  end
  def import
    @pagename ="ABOUT"
    @ga_page_category = 'about'

    if params[:id].nil?
      @menu = 1
    else
      @menu = params[:id]
    end
    render 'import'
  end
  def tos
    @pagename ="ABOUT"
    @ga_page_category = 'about'

    render 'tos', :layout=>false
  end
  def privacy
    @pagename ="ABOUT"
    @ga_page_category = 'about'

    render 'privacy', :layout=>false
  end

  def test_computer
      render :layout => false
  end

end
