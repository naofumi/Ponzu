# encoding: UTF-8
module KamishibaiWillPaginationHelper

  # Will paginate view helper with Kamishibai style links
  def ks_will_paginate(collection = nil, options = {})
    if galapagos?
      will_paginate collection, options
    else
      options.merge! previous_label: content_tag(:span, "previous", class: "button icon arrowleft big"), 
                     next_label: content_tag(:span, "next", class: "button icon arrowright big")
      will_paginate collection, options.merge(:renderer => KamishibaiWillPaginationHelper::LinkRenderer)
    end
  end

  class LinkRenderer < WillPaginate::ActionView::LinkRenderer
    # include Kamishibai::Controller

    private
 
    def ksp(*args)
      @template.send :ksp, *args
    end

    def param_name
      @options[:param_name].to_s
    end

    def link(text, target, attributes = {})
      if target.is_a? Fixnum
        attributes[:rel] = rel_value(target)
        target = url(target)
      end
      attributes[:href] = ksp(target)
      tag(:a, text, attributes)
    end
    
    def tag(name, value, attributes = {})
      string_attributes = attributes.inject('') do |attrs, pair|
        unless pair.last.nil?
          attrs << %( #{pair.first}="#{CGI::escapeHTML(pair.last.to_s)}")
        end
        attrs
      end
      "<#{name}#{string_attributes}>#{value}</#{name}>"
    end

    def rel_value(page)
      case page
      when @collection.current_page - 1; 'prev' + (page == 1 ? ' start' : '')
      when @collection.current_page + 1; 'next'
      when 1; 'start'
      end
    end

    def symbolized_update(target, other)
      other.each do |key, value|
        key = key.to_sym
        existing = target[key]
        
        if value.is_a?(Hash) and (existing.is_a?(Hash) or existing.nil?)
          symbolized_update(existing || (target[key] = {}), value)
        else
          target[key] = value
        end
      end
    end
  end
end