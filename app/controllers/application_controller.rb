# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  GetText.locale = "ja"
  init_gettext "application"
  helper :all # include all helpers, all the time
  helper_method :current_owner, :current_viewer, :is_owner?, :is_friend?
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password

  private
  def set_header
    if request.mobile? && request.mobile.is_a?(Jpmobile::Mobile::Docomo)
      headers['Content-Type'] = 'application/xhtml+xml;charset=Shift_JIS'
    end
  end
  
  def current_viewer
    session[:viewer]
  end
  
  def current_owner
    session[:owner]
  end
  
  def is_owner?
    current_viewer == current_owner
  end
  
  def is_friend?
    current_viewer.friends.member?(current_owner)
  end
  
  def adjust_session
    session[:owner].send(:remove_instance_variable, :@friends) if session[:owner] && session[:owner].send(:instance_variable_get, :@friends)
    session[:viewer].send(:remove_instance_variable, :@friends) if session[:viewer] && session[:viewer].send(:instance_variable_get, :@friends)
  end
  
  def validate_session
    if request.mobile? && !current_viewer
      MixiApi.register(request, params, session)
    end
    
    if current_viewer
      true
    else
      #session timeout
      respond_to do |format|
        format.html { redirect_to :controller => 'gadget', :action => 'timeout', :format => 'html' }
        format.js   { redirect_to :controller => 'gadget', :action => 'timeout', :format => 'js' }
      end
      false
    end
  end
  
  def validate_owner
    if is_owner?
      true
    else
      #invalid access?
      respond_to do |format|
        format.html { redirect_gadget_to :controller => 'gadget', :action => 'error', :format => 'html' }
        format.js   { redirect_gadget_to :controller => 'gadget', :action => 'error', :format => 'js' }
      end
      false
    end
  end
  
  def validate_friend
    if is_owner? || is_friend?
      true
    else
      #invalid access?
      respond_to do |format|
        format.html { redirect_gadget_to :controller => 'gadget', :action => 'error', :format => 'html' }
        format.js   { redirect_gadget_to :controller => 'gadget', :action => 'error', :format => 'js' }
      end
      false
    end
  end
  
  def redirect_gadget_to(options = {}, response_status = {})
    if options.is_a?(Hash)
#      options[:opensocial_owner_id] = current_owner.mixi_id if current_owner
      options[:viewer] = current_viewer
      options[:nocache] = DateTime.current.strftime("%Y%m%d%H%M%S")
      options[request.session_options[:key]] = request.session_options[:id]
    end
    redirect_to(options, response_status)
  end
  
  def mobile_gadget_url_for(options, with_transsid = true)
    if options.is_a?(Hash)
      if !with_transsid
        options[request.session_options[:key]] = nil
      else
        options[:nocache] = DateTime.current.strftime("%Y%m%d%H%M%S")
      end
    end
    url = "http://#{AppResources[:mixi_mobile_domain]}/#{AppResources[:application_id]}/?url="
    url << CGI.escape(url_for(options))
    url << "&amp;guid=ON" if request.mobile.is_a?(Jpmobile::Mobile::Docomo)
    url
  end
end
