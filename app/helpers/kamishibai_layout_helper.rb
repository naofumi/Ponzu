# kamishibai_layout_helper defines methods used repetitively
# to help us generate the application layout

module KamishibaiLayoutHelper

  # The ponzu_frame helper simplifies creation of Kamishibai elements.
  # It automatically generates the ID, data-title, data-container
  # and data-container_ajax attributes.
  #
  # It assumes that you will insert the block into a container DIV.
  # In Kamishibai in general, this is the recommended.
  #
  # Generates a ponzu_frame DIV with the ID auto-generated.
  # You can suffix the ID with options[:id_suffix]
  # You can also provide your own ID.
  # The default container will be "/ponzu_frame", but
  # can be specified with the :container option. 
  # The ID of the container, if ommited, will automatically
  # be set depending on the request.
  #
  # If the request is POST or PUT or the action is :new, :edit, :create
  # or :update, the ID will be set to "form_".
  #
  # We haven't yet worked out what the ID should ideally be.
  # The ID is important because in Kamishibai, we often redraw the
  # whole frame in response to an AJAX request.
  def ponzu_frame options = {}, &block
    container_string = options.delete(:container) || "ponzu_frame"
    options[:id] ||= [default_id_for_action, options[:id_suffix]].compact.join('_')
    options = normalize_page_options(options)
    options[:data] ||= {}
    options[:title_args] ||= {}
    title = t '.title', options[:title_args]
    options[:data][:title] = "#{t('titles.prefix')}#{title}"
    options[:data][:container] = container_string
    options[:data][:container_ajax] = static_path(:page => container_string)
    # Set min-height so that the location bar will always be hidden on iPhone
    options[:style] = "#{options[:style]};min-height:1000px"
    ks_element options, &block
  end

  def default_id_for_action
    action, controller, id = request.path_parameters.slice(:action, :controller, :id).values
    if id
      controller = ActiveSupport::Inflector.singularize controller
    end
    # In new/edit/create/update, we will normally be working on a single
    # form. We should share the ID so the element will be replaced with each
    # action.
    action = "form" if ["new", "edit", "create", "update"].include?(action) ||
                       request.post? || request.put?
    [action, controller, id].compact.join('_')
  end

end
