module Kamishibai
  module DeviceSupport
    FEATURE_PHONE_URL_SCOPE = 'feature_phone' # Galapagos
    SMARTPHONE_URL_SCOPE = 'smartphone'
    DESKTOP_URL_SCOPE = 'pc'
    
    def self.included(base)
      base.helper_method :smartphone?, :galapagos?, :device_scope_by_user_agent
      base.layout :device_layout
      base.before_filter :set_device

      base.extend(ClassMethods)
    end

    module ClassMethods
    end

    # helper_method :ksp
    private

    def set_device
      @device = device_scope_by_user_agent
      cookies[:device] = @device
    end

    # def redirect_unless_locale_in_path
    #   if !params[:locale] && params[:action] != 'cache_manifest'
    #     redirect_to root_path(:device => device_scope_by_user_agent)
    #   end
    # end

    # 'g' for galapagos feature phones
    # 's' for smartphones
    # '' for desktop
    def device_scope_by_user_agent
      return FEATURE_PHONE_URL_SCOPE unless request.headers['HTTP_USER_AGENT']
      case 
      when request.headers['HTTP_USER_AGENT'] =~ /iPad/i
        DESKTOP_URL_SCOPE
      when request.headers['HTTP_USER_AGENT'] =~ /iPhone|iPod/i # Includes chrome for iPhone
        SMARTPHONE_URL_SCOPE
      when request.headers['HTTP_USER_AGENT'] =~ /Android 1/i # Android versions 1.*
        FEATURE_PHONE_URL_SCOPE
      when request.headers['HTTP_USER_AGENT'] =~ /Android 2.(1|2)/i # Android versions 2.1, 2.2
        FEATURE_PHONE_URL_SCOPE
      when request.headers['HTTP_USER_AGENT'] =~ /Android/i # Includes chrome, firefox for android
        SMARTPHONE_URL_SCOPE
      when request.headers['HTTP_USER_AGENT'] =~ /Silk|Kindle/i # Kindle Fire might be a bit more quirkier
        SMARTPHONE_URL_SCOPE
      when request.headers['HTTP_USER_AGENT'] =~ /MSIE 8|MSIE 9|MSIE 10/i &&
           request.headers['HTTP_USER_AGENT'] !~ /phone/i
        DESKTOP_URL_SCOPE
      when request.headers['HTTP_USER_AGENT'] =~ /MSIE 9/i &&
           request.headers['HTTP_USER_AGENT'] =~ /phone/i
        SMARTPHONE_URL_SCOPE
      when request.headers['HTTP_USER_AGENT'] =~ /applewebkit/i
        DESKTOP_URL_SCOPE
      when request.headers['HTTP_USER_AGENT'] =~ /gecko/i && # Firefox 10 and later
           request.headers['HTTP_USER_AGENT'] =~ /Firefox\/(1|2|3|4|5)\d/i
        DESKTOP_URL_SCOPE
      when request.headers['HTTP_USER_AGENT'] =~ /rv:1/i && # IE 11 and maybe later
        DESKTOP_URL_SCOPE
      else
        FEATURE_PHONE_URL_SCOPE
      end
    end

    def uses_jquery?
      request.headers['HTTP_USER_AGENT'] =~ /MSIE 8|MSIE 9/
    end

    def smartphone?
      @device == SMARTPHONE_URL_SCOPE
    end

    def galapagos?
      @device == FEATURE_PHONE_URL_SCOPE
    end

    def device_layout
      case @device
      when SMARTPHONE_URL_SCOPE
        "application"
        # "layouts/smartphone"
      when FEATURE_PHONE_URL_SCOPE
        "layouts/galapagos"
      else
        "application"
      end
    end

    # For Galapagos
    def set_shift_jis_content_type
      headers["Content-Type"] = "text/html; charset=Shift_JIS"
    end
    
    def set_utf_8_content_type
      headers["Content-Type"] = "text/html; charset=UTF-8"
    end

    def render_sjis(*args, &block)
      set_shift_jis_content_type
      self.response_body = render_to_string(*args, &block).encode!("Shift_JIS",
                                                                   :invalid => :replace,
                                                                   :undef => :replace)
      return
    end
  end
end