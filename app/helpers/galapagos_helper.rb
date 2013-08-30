# encoding: UTF-8

module GalapagosHelper
  def g(string)
    string ? string.encode("SJIS").html_safe : ""
  end
  
  # http://www.weblan3.com/mobile/reference-mobilesite-3c.php
  def body_text
    @body_text ||= "#000000"
  end
  
  def body_bg
    @body_bg ||= "#FFFFFF"
  end
  
  def body_link
    @body_link ||= "#0000FF"
  end
  
  def body_vlink
    @body_vlink ||= "#0000FF"
  end
  
  def body_alink
    @body_alink ||= "#FFFFFF"
  end
  
  def hr
    "<hr style=\"border-color:#999999; border-style:solid;\" />".html_safe
  end

  def san
    "<div style='border-bottom: solid 1px #BBBBBB'></div>".html_safe
    # "<span style=\"color:#999999;\">…………………………</span>".html_safe
  end

  def galapagos_hidden_fields(options)
    options[:method] ||= 'post'
    hidden_field_tag(:_method, options[:method]) +
    hidden_field_tag(:authenticity_token, form_authenticity_token) +
    hidden_field_tag(:utf8, "✓")
  end

  def galapagos_bullet
    '<span class="pink">■</span> '.html_safe
  end
end