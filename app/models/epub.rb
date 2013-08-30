# encoding: UTF-8

# A convention over configuration oriented epub exporter.
# We assume that each ActiveRecord object you include in the epub corresponds
# to a page (xhtml file). In our case, each Session object has a page and
# each Presentation object has a page.
# 
# If you want to use non-ActiveRecord objects as pages, (i.e. if you want to 
# create a section dividing page), create a corresponding object and add
# that in the config file to the toc, spine, or manifest stuff. This object
# should implement #id to identify it. You also need to create the views and
# stuff.
#
# Each element that represents a page AND will be written to the toc must
# implement a #epub_nav_text method. The result of this method will be used
# for the TOC line text.
#
# Each object that is included will be written into the epub using an Erb
# template that lives in app/views/epub/[object_name_underscored].
# The xhtml file for that object will be included in the epub as
# OEBPS/[object_name_underscored]_[id].xhtml
#
# Configuration of the epub is done in the "config.rb" file that
# lives in the epub directory "epubs/[epub_name]/config.rb"
#
# The config file will generate the following instance variables.
# @objects : An Array (or Set) of objects that will be included in the epub.
# @toc_list : An nested Array (or Set) of objects that will be displayed in the table-of-contents
# @spine : An Array of objects that represent the viewing order.
# 
# The cover image must be in the "OEBPS/images" folder and have a filename
# that is either "cover.jpg" "cover.png" "cover.gif", depending on the image format.
#
# The cover page HTML file must be named "OEBPS/cover.html"
#
# The "META-INF/container.xml" file template resides in "app/views/epub/container.xml".
# It is used as is.
#
# The "mimetype" file template resides in "app/views/epub/mimetype".
# It is used as is.
#
# The "OEBPS/toc.ncx" file is generated from the template in "app/views/epub/toc.ncx.erb"
# You generally won't need to change this file.
#
# Generating the epub:
#   rake epub:create EPUB=[epub_name] RAILS_ENV=[environment]
#
# Considerations:
# Compared to how browsers handle errors in HTML documents, the syntax requirements for
# epubs can be very strict. It is strongly advisable that you get no errors after
# running epubcheck.
# Hence we do strict validation of the xhtml using Nokogiri and we decode entities
# that have a UTF8 counterpart. Any remnant '&'s are converted to '&amp;' so that
# the validator will not complain.
#
# View helpers:
# You can use any view helpers that do not require references to requests or controllers.
# This excludes anything that uses url_for, and hence we provide our own helpers.
# For example, we provide our own #link_to method which mimics some of the functionality
# of the ActionView link_to helper.
#
# Erb limitations:
# At this time, we only provide the bare ERB functionality in the Ruby standard library.
# None of the Rails extentions are present. We don't have partials and stuff. This is
# not so much of an issue in an ePub because you don't put 'chrome' in ePubs anyway.
require 'erb'
require 'nokogiri'

class Epub
  include PresentationsHelper
  include ActionView::Helpers::SanitizeHelper

  def initialize(epub_name)
    # A simple delegate would be easier to understand
    @epub_name = epub_name
    require File.expand_path("../../../epubs/#{epub_name}_config.rb", __FILE__)
    class << self
      include EpubConfig
    end
  end
  
  def export_xhtml
    objects.each do |o|
      instance_variable_set("@#{o.class.to_s.underscore}".to_sym, o) # Session -> @session
      template = ERB.new File.read(default_view_template_filename(o))
      FileUtils.mkdir_p(default_xhtml_directory(o))
      File.open(default_xhtml_filename(o), "w") do |out|
        out.write template.result(binding)
      end
    end
  end
  
  def export_toc
    nav_map_elements = []
    toc_array.each do |node|
      nav_map_elements << toc_entry_for_node(node)
    end
    @nav_map = nav_map_elements.join("\n")
    template = ERB.new File.read("#{Rails.root}/app/views/epub/toc.ncx.erb")
    File.open(default_toc_ncx_filename, "w") do |out|
      out.write tidy_xml(template.result(binding))
    end
  end
  
  def export_content(params = {})
    @content_manifests = manifest_xml(:image_files => params[:image_files],
                                      :xhtml_files => params[:xhtml_files])
    @spine = spine.map{|o| "<itemref idref=\"#{default_identifier(o)}\"/>"}.join("\n")
    template = ERB.new File.read("#{Rails.root}/app/views/epub/content.opf.erb")
    File.open(default_content_opf_filename, "w") do |out|
      out.write tidy_xml(template.result(binding))
    end
  end
  
  private

  def manifest_xml(params)
    image_files = params[:image_files] || []
    xhtml_files = params[:xhtml_files] || []
    image_files.to_a.map{|file| image_manifest(file)}.compact.join("\n") + "\n" +
    xhtml_files.to_a.delete_if{|f| f =~ /cover\.xhtml$/}.
                     map{|file| xhtml_manifest(file)}.compact.join("\n")
  end
  
  def image_manifest(file)
    if file =~ /\.(jpeg|jpg|png|gif|svg)$/
      type = case $1
             when 'jpeg', 'jpg'
               'image/jpeg'
             when 'png'
               'image/png'
             when 'gif'
               'image/gif'
             when 'svg'
               'image/svg+xml'
             end
      identifier = File.basename(file).gsub(/[\. ]/, '_')
      href = "#{Rails.root}/#{file}".sub("#{default_oebps_directory}/", "")
      %Q|<item id="#{identifier}" href="#{href}" media-type="#{type}"/>|
    else
      nil
    end
  end

  def xhtml_manifest(file)
    if file =~ /\.(html|htm|xhtml)$/
      identifier = File.basename(file).gsub(/[\. ]/, '_')
      href = "#{Rails.root}/#{file}".sub("#{default_oebps_directory}/", "")
      %Q|<item id="#{identifier}" href="#{href}" media-type="application/xhtml+xml"/>|
    else
      nil
    end
  end



  def book_id
    "urn:uuid:mbsj2012-#{Time.now.strftime('%Y%m%d%H%M%S')}"
  end
  
  def xsl
    @xsl ||= Nokogiri::XSLT(File.read("#{Rails.root}/config/pretty_print.xsl"))
  end
  
  def tidy_xml(string)
    xsl.apply_to(Nokogiri::XML(string)).to_s
  end
  
  def play_order
    @play_order ||= 0
    @play_order += 1
  end
  
  def toc_entry_for_node(node)
    po = play_order
    result = []
    if node.class == Hash
      object = node.keys.first
      children = node.values.first
    else
      object = node
      children = []
    end
template = ERB.new <<-NODE
<navPoint id="navpoint-<%= po %>" playOrder="<%= po %>">
  <navLabel>
    <text><%= decode_entities(strip_tags(object.epub_nav_text)) %></text>
  </navLabel>
  <content src="<%= relative_xhtml_filename(object) %>"/>
  <% children.map do |c| %>
    <%= toc_entry_for_node(c) %>
  <% end %>
</navPoint>
NODE
    template.result(binding)
  end
  
  def default_view_template_filename(o)
    template = "#{Rails.root}/app/views/epub/" + o.class.to_s.underscore + ".xhtml.erb"
  end
  
  def default_toc_ncx_filename
    "#{default_oebps_directory}/toc.ncx"
  end

  def default_content_opf_filename
    "#{default_oebps_directory}/content.opf"
  end
  
  def default_xhtml_filename(o)
    "#{default_xhtml_directory(o)}/#{o.class.to_s.underscore}_#{o.id}.xhtml"
  end
  
  def relative_xhtml_filename(o)
    "#{o.class.to_s.underscore.pluralize}/#{o.class.to_s.underscore}_#{o.id}.xhtml"
  end
  
  def default_identifier(o)
    "#{o.class.to_s.underscore}_#{o.id}_xhtml"
  end
  
  def default_xhtml_directory(o)
    directory_path = "#{default_oebps_directory}/#{o.class.to_s.underscore.pluralize}"
    FileUtils.mkdir_p directory_path
    directory_path
  end
  
  def default_oebps_directory
    directory_path = "#{Rails.root}/epubs/#{@epub_name}/OEBPS"
    FileUtils.mkdir_p directory_path
    directory_path
  end
  
  def link_to(*args)
    args[0]
  end

  # Override the link_to method which is used in the PresentationsHelper
  def clean_xml_epub(string)
    return "" unless string
    # <u> is deprecated in the spec
    string = string.gsub(/<BR[ \/]*>/i, "\n").
             gsub(/<([\/]?)I>/, '<\1i>').gsub(/<([\/]?)B>/, '<\1b>').
             gsub(/<([\/]?)U>/i, '').
             gsub(/<([\/]?)SUP>/, '<\1sup>').gsub(/<([\/]?)SUB>/, '<\sub>').
             gsub(/<([\/]?)span>/i, '').gsub(/<([\/]?)div>/i, '')
    doc = Nokogiri::XML("<doc></doc>", nil, 'UTF-8')
    frag = Nokogiri::XML::DocumentFragment.new(doc, string)
    frag.to_xml
  end

  def decode_entities(string)
    @coder = HTMLEntities.new
    @coder.decode(string).gsub(/&/, '&amp;')
  end
end