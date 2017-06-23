class WikiController < ApplicationController

  before_filter :init_logged_user, :prevent_browser_cache, :save_origin_url  #init the graph connection and everyhting user related
  #use the application layout which has header and footer
  ####
  ## wiki pages are XXX-YYY where XXX is the directory and YYY the pagename
  ####

  layout 'main_layout'
  ## edits a wiki page in [:pagename]


  def update
    begin
      raise DBTechnicalError.new "User must be logged in" if @user.nil?
      raise DBTechnicalError.new "Missing object id" if (id = params[:id]).blank?
      raise DBTechnicalError.new "Missing object type" if params[:type].blank?
      type = Object::const_get(params[:type].titleize) ## sometimes u get "country" instead of "Country"
      raise DBTechnicalError.new "Empty wiki text" if params[:text].blank?
      entry = type.find(id.to_i)

      w = Wiki.create_wiki entry.class.to_s, id.to_i, params[:text], @user.id
      raise DBTechnicalError.new "Could not save the new entry" if w.nil?
      render :json => {:success => true, :data => {:id => w.id, :data => w.data}}
    rescue
      render :json => {:success => false, :error => $!.message}

    end

  end
end
