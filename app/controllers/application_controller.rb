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
  
  def validate_session
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
    options[:viewer] = current_viewer
    options[request.session_options[:key]] = request.session_options[:id]
    redirect_to(options, response_status)
  end
end
