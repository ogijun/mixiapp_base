# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  GetText.locale = "ja"
  init_gettext "application"
  helper :all # include all helpers, all the time
  helper_method :current_owner, :current_viewer, :is_owner?, :is_friend?
  #protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password

  transit_sid :always
  mobile_filter :hankaku => true
  emoticon_filter :editable_tag => false
  after_filter :set_header

  private
  def set_header
    if request.mobile? && request.mobile.is_a?(Jpmobile::Mobile::Docomo)
      headers['Content-Type'] = 'application/xhtml+xml;charset=Shift_JIS'
    end
  end
  
  def current_viewer
    session[:viewer] ? session[:viewer].dup : nil
  end
  
  def current_owner
    session[:owner] ? session[:owner].dup : nil
  end
  
  def is_owner?
    current_viewer == current_owner
  end
  
  def is_friend?
    current_viewer.friends.member?(current_owner)
  end
  
  def validate_session
    is_error = false
    if request.mobile? && !current_viewer
      begin
        MixiApi.register_mobile(session, params['opensocial_owner_id'])
      rescue Timeout::Error
        logger.error "MixiApi.register_mobile TIMEOUT ERROR!"
        is_error = true
      rescue
        logger.error "MixiApi.register_mobile ERROR!"
        is_error = true
      end
    end
    
    if is_error
      #API timeout
      respond_to do |format|
        format.html { redirect_gadget_to :controller => 'gadget', :action => 'error', :format => 'html' }
        format.js   { redirect_gadget_to :controller => 'gadget', :action => 'error', :format => 'js' }
      end
      false
    elsif !current_viewer
      #session timeout
      respond_to do |format|
        format.html { redirect_gadget_to :controller => 'gadget', :action => 'timeout', :format => 'html' }
        format.js   { redirect_gadget_to :controller => 'gadget', :action => 'timeout', :format => 'js' }
      end
      false
    else
      true
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
        format.html { redirect_gadget_to :controller => 'gadget', :action => 'error_friend', :format => 'html' }
        format.js   { redirect_gadget_to :controller => 'gadget', :action => 'error_friend', :format => 'js' }
      end
      false
    end
  end
  
  def redirect_gadget_to(options = {}, response_status = {})
    if options.is_a?(Hash)
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
