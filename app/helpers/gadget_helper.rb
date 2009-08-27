module GadgetHelper
  unless const_defined? :JQUERY_VAR
    JQUERY_VAR = '$'
  end
  def link_to_update(name, options = {}, html_options = nil)
    link_to_function(name, update_function(options), html_options || options.delete(:html))
  end
  def link_to_script(name, options = {}, html_options = nil)
    link_to_function(name, script_function(options), html_options || options.delete(:html))
  end
  def link_to_navigate(name, options = {}, html_options = nil)
    link_to_function(name, navigate_function(options), html_options || options.delete(:html))
  end
  def link_to_external(name, options = {}, html_options = nil)
    link_to_function(name, external_function(options), html_options || options.delete(:html))
  end
  
  def button_to_update(name, options = {}, html_options = nil)
    button_to_function(name, update_function(options), html_options)
  end
  def button_to_script(name, options = {}, html_options = nil)
    button_to_function(name, script_function(options), html_options)
  end
  def button_to_navigate(name, options = {}, html_options = nil)
    button_to_function(name, navigate_function(options), html_options)
  end
  def button_to_external(name, options = {}, html_options = nil)
    button_to_function(name, external_function(options), html_options)
  end

  def update_function(options = {})
    request_function(options, "#{JQUERY_VAR}.mixigadget.requestContainer")
  end
  def script_function(options = {})
    request_function(options, "#{JQUERY_VAR}.mixigadget.requestScript")
  end
  def navigate_function(options = {})
    navigate_tag = "gadgets.views.requestNavigateTo("
    navigate_tag += "new gadgets.views.View('#{options[:view]}')"
    navigate_tag += ", {" + (options[:url] ? "'url':'#{escape_javascript(url_for(options[:url]))}'" : "") + "}"
    navigate_tag += ", #{options[:owner_id]}" if options[:owner_id]
    navigate_tag += ");"
    navigate_tag
  end
  def external_function(options = {})
    "mixi.util.requestExternalNavigateTo('#{escape_javascript(options[:url])}');"
  end
  
  def post_activity(options = {})
    post_tag = "var params = {};\n"
    post_tag += "params[opensocial.Activity.Field.TITLE] = '#{options[:title]}';\n"
    
    if options[:recipients]
      post_tag += "params[mixi.ActivityField.RECIPIENTS] = [#{options[:recipients].join(",")}];\n"
    end
    
    if options[:images]
      post_tag += "var mitems = [];\n"
      options[:images].each do |image|
        mime_type = ""
        if /\.png$/i =~ image
          mime_type = "image/png"
        elsif /\.jp(g|eg)$/i =~ image
          mime_type = "image/jpeg"
        else
          mime_type = "image/gif"
        end
        post_tag += "mitems.push(opensocial.newMediaItem('#{mime_type}', '#{image}'));"
      end
      
      post_tag += "params[opensocial.Activity.Field.MEDIA_ITEMS] = mitems;\n"
    end

    post_tag += "var activity = opensocial.newActivity(params);\n"
    post_tag += "opensocial.requestCreateActivity(activity, opensocial.CreateActivityPriority.HIGH, function(response) { #{options[:function]} });\n"
    post_tag
  end

  def post_share_app(options = {})
    "opensocial.requestShareApp('VIEWER_FRIENDS', null, function(response) { #{options[:function]} });\n"
  end

  protected
  def request_function(options, function_name)
    function = "#{function_name}("
    
    url_options = options[:url]
    url_options = url_options.merge(:escape => false) if url_options.is_a?(Hash)
    function << "'#{escape_javascript(url_for(url_options))}'"
    
    param_options = '{}'
    if options[:form]
      param_options = "#{JQUERY_VAR}.param(#{JQUERY_VAR}(this).serializeArray())"
    elsif options[:submit]
      param_options = "#{JQUERY_VAR}('##{options[:submit]} :input').serialize()"
    elsif options[:with]
      if options[:with].is_a?(Array) || options[:with].is_a?(Hash)
        param_options = "#{options[:with].to_json.gsub(/\"/,"'")}"
      else
        param_options = "'#{options[:with]}'"
      end
    end
    function << ", #{param_options}" if param_options != '{}' || options[:method]
    
    if options[:method]
      case options[:method].downcase
      when "get"
        function << ", gadgets.io.MethodType.GET"
      when "post"
        function << ", gadgets.io.MethodType.POST"
      end
    end

    function << ")"

    return function
  end
end
