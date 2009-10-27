class GadgetController < ApplicationController
  caches_page :index
  transit_sid :mobile
  mobile_filter :hankaku => true
  protect_from_forgery :except => ["index", "register", "top", "timeout"]
  before_filter :validate_session, :only => [:top]
  after_filter :adjust_session, :only => [:register, :top]
  after_filter :set_header
  
  def index
    respond_to do |format|
      format.xml
    end
  end
  
  def register
    MixiApi.register(request, params, session)
    redirect_gadget_to :controller => "gadget", :action => "top"
  end
  
  def top
  end
  
  def home
    render :layout => false
  end

  def profile
    render :layout => false
  end
  
  def preview
    render :layout => false
  end
  
  def timeout
  end
  
  def error
  end

end
