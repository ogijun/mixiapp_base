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
    navigate_tag += "new gadgets.views.View('#{options[:view]}'), {"
    navigate_tag += "'nocache':'#{DateTime.current.strftime("%Y%m%d%H%M%S")}',"
    navigate_tag += "'url':'#{escape_javascript(url_for(options[:url]))}'" if options[:url]
    navigate_tag += "," if options[:url] && options[:session]
    navigate_tag += "'session_key':'#{escape_javascript(request.session_options[:key])}','session_id':'#{escape_javascript(request.session_options[:id])}'" if options[:session]
    navigate_tag += "}"
    navigate_tag += ", #{options[:owner_id]}" if options[:owner_id]
    navigate_tag += ")"
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

    if options[:url]
      post_tag += "params[opensocial.Activity.Field.URL] = 'http://mixi.jp/run_appli.pl?id=#{AppResources[:application_id]}&'+gadgets.io.encodeValues({appParams: gadgets.json.stringify({url: '#{escape_javascript(url_for(options[:url]))}'})});\n"
    end

    post_tag += "var activity = opensocial.newActivity(params);\n"
    post_tag += "opensocial.requestCreateActivity(activity, opensocial.CreateActivityPriority.HIGH, function(response) { #{options[:function]} });\n"
    post_tag
  end

  def post_share_app(options = {})
    "#{JQUERY_VAR}.mixigadget.requestInvite(#{options[:function]});\n"
  end
  
  def link_to_diary(name, title, body, mixi_id, html_options = nil)
    if !request.mobile?
      url = "http://mixi.jp/add_diary.pl?diary_title="
      url << CGI.escape(title.toeuc)
      url << "&diary_body="
      url << CGI.escape(body.toeuc)
      url << "&id="
      url << mixi_id
    elsif request.mobile.is_a?(Jpmobile::Mobile::Softbank)
      url = "http://m.mixi.jp/add_diary.pl?diary_title="
      url << CGI.escape(title)
      url << "&diary_body="
      url << CGI.escape(body)
      url << "&id="
      url << mixi_id
    else
      url = "http://m.mixi.jp/add_diary.pl?diary_title="
      url << CGI.escape(title.tosjis)
      url << "&diary_body="
      url << CGI.escape(body.tosjis)
      url << "&id="
      url << mixi_id
      url << "&guid=ON" if request.mobile.is_a?(Jpmobile::Mobile::Docomo)
    end
    link_to(name, url, html_options)
  end
  
  def post_to_diary(name, title, body, mixi_id)
    url = "http://m.mixi.jp/add_diary.pl"
    url << "?guid=ON" if request.mobile.is_a?(Jpmobile::Mobile::Docomo)

    html = %Q(<form action="#{url}" method="post">\n)
    html << %Q(<input type="hidden" name="diary_title" value="#{CGI.escapeHTML(title)}" />\n)
    html << %Q(<input type="hidden" name="diary_body" value="#{CGI.escapeHTML(body).gsub(/\n/, "&#xA;")}" />\n)
    html << %Q(<input type="hidden" name="id" value="#{mixi_id}" />\n)
    html << %Q(<input type="submit" value="#{name}" />\n)
    html << %Q(</form>\n)
    html
  end

  def mobile_gadget_link_to(name, options = {}, html_options = nil)
    if development?
      options[:opensocial_owner_id] ||= params[:opensocial_owner_id] if options.is_a?(Hash)
      link_to(name, options, html_options)
    else
      options[:nocache] ||= DateTime.current.strftime("%Y%m%d%H%M%S") if options.is_a?(Hash)
      link_to(name, mobile_gadget_url_for(options), html_options)
    end
  end
  def mobile_gadget_form_for(record_or_name_or_array, *args, &proc)
    options = args.extract_options!
    if development?
      options[:url][:opensocial_owner_id] ||= params[:opensocial_owner_id]
    else
      options[:url] = mobile_gadget_url_for(options[:url])
    end
    form_for(record_or_name_or_array, *(args << options), &proc)
  end
  def mobile_gadget_form_tag(url_for_options = {}, options = {}, *args, &proc)
    if development?
      url_for_options[:opensocial_owner_id] ||= params[:opensocial_owner_id]
      form_tag(url_for_options, options, *args, &proc)
    else
      form_tag(mobile_gadget_url_for(url_for_options), options, *args, &proc)
    end
  end
  def mobile_gadget_url_for(options, with_transsid = true)
    @controller.send(:mobile_gadget_url_for, options, with_transsid)
  end

  def mobile_gadget_paginating_links(paginator, options = {}, html_options = {})
    name = options[:name] || PaginatingFind::Helpers::DEFAULT_OPTIONS[:name]
    params = (options[:params] || PaginatingFind::Helpers::DEFAULT_OPTIONS[:params]).clone
    
    mobile_gadget_paginating_links_each(paginator, options) do |n|
      params[name] = n
      mobile_gadget_link_to(n, params, html_options)
    end
  end
  
  def mobile_gadget_paginating_links_each(paginator, options = {})
    return if paginator.last_page==paginator.first_page
    
    options = PaginatingFind::Helpers::DEFAULT_OPTIONS.merge(options)
    
    window = ((paginator.page - options[:window_size] + 1)..(paginator.page + options[:window_size] - 1)).select {|w| w >= paginator.first_page && w <= paginator.last_page }
    
    html = ''
    
    if options[:always_show_anchors] && !window.include?(paginator.first_page)
      html << yield(paginator.first_page)
      html << ' ... ' unless window.first - 1 == paginator.first_page
      html << ' '
    end
    
    window.each do |p|
      if paginator.page == p && !options[:link_to_current_page]
        html << p.to_s
      else
        html << yield(p)
      end
      html << ' '
    end
    
    if options[:always_show_anchors] && !window.include?(paginator.last_page)
      html << ' ... ' unless window.last + 1 == paginator.last_page
      html << yield(paginator.last_page)
    end
    
    html
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
  
  def development?
    AppResources[:development]
  end
end
