# encoding: utf-8

module PonzuHelper
  include ConferenceStrings

  def manifest_attribute
    manifest_path =  "/manifest"
    @set_manifest ? "manifest='#{manifest_path}.appcache'".html_safe : ""
  end

  # Use to add comments to the HTML to
  # communicate future intentions to alpha testers
  def todos(*list_of_todos)
    if (false && Rails.env == "development")
      render :partial => "layouts/todo", 
             :locals => {:todos => list_of_todos}
    end
  end
  
  # Deprecated
  def keitai_url_for(url)
    url.sub(/https?:\/\/([^\/]+)/, 'm.mbsj2012.castle104.com')
  end

  def scss_color_palette
<<SCSS_COLOR_PALETTE
$text: #555;
$mbsj_pink : #F70039;
$link: #053175;
$light_gray: #888;
$background_gray: #f7f4f5;
$very_light_gray: #BBB;
$mbsj_dark_pink: #C2244F;
$extreme_light_gray: #EEE;
SCSS_COLOR_PALETTE
  end

  # Combines the starts_at and ends_at of an object
  # into a single string using the localized format.
  #
  # You can specify :separator => " ~ " 
  def starts_at_ends_at_combo(obj, format, options = {})
    separator = options[:separator] || " - "
    raise "format is not set" unless format
    starts_at_string = obj.starts_at && l(obj.starts_at, :format => format)
    ends_at_string = obj.ends_at && l(obj.ends_at, :format => format)
    "#{starts_at_string}#{separator}#{ends_at_string}"
  end

  # Generates string 'field_with_errors' if validation failed for a value
  def error_indicator(ar_object, field_name)
    if ar_object.errors.include?(field_name.to_sym)
      'field_with_errors'
    else
      ''
    end
  end

end
