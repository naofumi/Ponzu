module KamishibaiHelper

  # Use this to set the default Kamishibai hash inside the head tag.
  # (the hash that is set when location.hash is empty)
  # Kamishibai will automatically pick this up.
  def default_kamishibai_hash_tag(href)
    tag(:meta, :name => "default_kamishibai_hash", :content => href)
  end

  # We use this to generate a unique ID for each search string.
  # Since we won't decode it, we can use anything we like that
  # returns a string that is id-attribute friendly.
  # SHA returns fixed length so is kind on the DOM.
  def encoded_query
    require 'digest'
    Digest::SHA1.hexdigest(params[:query].to_s)
  end

  ###################################
  # Page, Element helpers
  ###################################

  # For pages that will be read in via ajax
  def ks_page(options, &block)
    options = normalize_page_options(options)
    raise "ks_page element cannot be inside a container" if options[:data] && options[:data][:container]

    options[:class].push('page').uniq.compact
    ks_element(options, &block)
  end

  # A page that is initially hidden (i.e. pages in a multipage document)
  def ks_hidden_page(options, &block)
    options = normalize_page_options(options)
    options[:style] = "display:none;" + options[:style].to_s
    ks_page(options, &block)
  end

  # A page that is initially hidden and is loaded as a placeholder
  def ks_hidden_ajax_placeholder_page(options)
    options = normalize_page_options(options)
    raise("#{__method__} must have an :'data-ajax'") unless options[:'data-ajax'] || options[:data][:ajax]
    ks_hidden_page(options){""}
  end

  # A placeholder sub-element that loads content from Ajax
  def ks_ajax_placeholder(options)
    options = normalize_page_options(options)
    raise("#{__method__} must have an :'data-ajax'") unless options[:'data-ajax'] || options[:data][:ajax]
    ks_element(options){""}
  end

  # A placeholder sub-element that does not fire Ajax itself.
  # Instead, it is a recepient of elements that have been loaded by Ajax
  # and target this sub-element via their id.
  def ks_placeholder(options)
    options = normalize_page_options(options)
    raise("#{__method__} must not have an :'data-ajax'") if options[:'data-ajax'] || options[:data][:ajax]
    ks_element(options){""}
  end

  # A ks-element that holds content
  def ks_element(options, &block)
    raise("#{__method__} must have an :id") unless options[:id]
    options = normalize_page_options(options)

    if Rails.configuration.kamishibai_cache
      expiry = options[:data][:expiry] || options[:'data-expiry'] || @expiry || Kamishibai::Cache::DEFAULT_EXPIRY
    else
      expiry = 0
    end
    options[:data][:expiry] = expiry

    content_tag(:div, options, nil, true, &block)    
  end

  def ks_hidden_element(options, &block)
    options = normalize_page_options(options)
    options[:style] = "display:none;" + options[:style].to_s
    ks_element(options, &block)    
  end

  # use internally to make specifying options for the helpers easier.
  # For example, we can set the :id with an array.
  def normalize_page_options(options)
    options.symbolize_keys!
    options = arrayify_options(options, {:class => ' '})
    if options[:id].kind_of? Array
      options[:id] = options[:id].join('_')
    end
    options
  end

  def arrayify_options(options, attribute_delimiter_hash)
    attribute_delimiter_hash.each do |attribute, delimiter|
      options[attribute] = options[attribute].split(delimiter) if options[attribute].kind_of? String
      options[attribute] ||= []
    end
    options[:data] ||= {}
    options
  end

  ###################################
  # DOM compositing helpers
  ###################################

  # ks_modify_elements "left_navigation" => {add_class: "selected"},
  #                 ["menu", 4] =>  {remove_class: "selected"},
  #                 ["bookmark", 5] => :remove
  #
  # Creates multiple elements that modify pre-existing elements 
  # when passed through KSDom.insertAjaxResponseIntoDom().
  #
  # This helper provides a much nicer API compared to directly generating
  # the elements and attributes in HTML, ERB or HAML.
  #
  # The modification symbols like :add_class are automatically 
  # converted to 'data-add-class' when they become HTML attributes.
  # 
  # You can also use a block to specify the modifications, which
  # can make it easier to use write complex logic.
  #
  # ks_modify_elements do |document|
  #   document["left_navigation"][:add_class] = "selected"
  #   document[["menu", 4]] = {remove_class: "selected"}
  #   document["bookmark"] = :remove
  # end
  def ks_modify_elements(options = {})
    html = ""
    block_options = Hash.new{|hash, key| hash[key] = {}}
    if block_given?
      yield block_options
    end
    options.update block_options

    options.each do |key, value|
      key = key.join('_') if key.kind_of? Array
      attributes = ""
      common_attributes = {id: key}
      common_data = {"attributes-only" => true}
      if value.kind_of? Hash
        html << content_tag(:div, "", common_attributes.merge(data: common_data.merge(value)))
      elsif value.kind_of?(Symbol) || value.kind_of?(String)
        html << content_tag(:div, "", common_attributes.merge(data: common_data.merge(value => true)))
      end
    end
    html.html_safe
  end

  ###################################
  # Widget generators
  ###################################

  # Encapsulates the collection in a list.
  # Useful for generating iOS-type list of links.
  def ks_linked_list(collection, &block)
    content_tag :ul do
      collection.map do |member|
        content_tag :li do
          capture(member, &block)
        end
      end.join("\n").html_safe
    end
  end


end