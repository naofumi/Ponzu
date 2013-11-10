# The parent class for all sessions that are location/booth based.
# For example, Session::Booth and Session::Poster.
#
# == Differences from Session::TimeTableable
#
# The #starts_at and #ends_at times have different meanings compared to
# Session::TimeTableable sessions.
#
# +starts_at+, +ends_at+::
#   These inidicate the times when the booths/posters are set up
#   and when they are taken down. They do not inidicate, for example,
#   when the author is going to be standing by their poster for
#   discussions. That will be set inside Presentation::Poster#starts_at
#   and Presentation::Poster#ends_at
#
# == Displaying the objects in a dynamic map
#
# To display a Session::Mappable session as a dynamic map, the following
# methods must be implemented.
#
# To learn about how to implement Mappable Sessions and Mappable Presentations,
# look at the following modules.
#
# 1. PosterNumberToGrid : This returns a Grid object for a poster. Include a subclass into
#    the Presentation::Poster class. For Presentation::Booth, we have to manually
#    input values for the grids because they cannot be automatically calculated.
# 2. PosterGrid, ExhibitionGrid : Converts Grid objects into x, y CSS pixel coordinates
#    for display. Instantiated within the view.
# 3. GridMixin : Included into PosterGrid, ExhibitionGrid to enable calculations
#    that are used to generate CSS to draw onto the screen.
#
# For each separate conference, we have to write the following files;
#
# 1. <b>PosterNumberToGrid::[conference symbol]:</b> Assign each poster number to a location (grid).
#    Assignment changes based on how many posters are on each row, how many rows we have, etc.
#    Include this into the Presentation::Poster class.
# 2. <b>PosterGrid::[conference symbol], ExhibitionGrid::[conference symbol]:</b> 
#    Calculate the CSS coordinates for each grid.
#    Depends on the zoom level of the underlying poster hall map, the spacing between rows, etc.
#    Implement as a subclass of PosterGrid. Set Session::Poster::GRID to this value which will
#    so that it can be instantiated in the view.
#
# == Testing PosterNumberToGrid
# 
# We use the unit testing framework to ensure that our custom PosterNumberToGrid is 
# generating the correct grid.
#
# == Testing the dynamic map
#
# The dynamic map can be tested via PosterSessionsController#show_test.
# Check the URL to access this action in routes.rb.
#
# == The view
#
# With these modules in place, the #show template would look something like this;
# 
# (HAML file: views/poster_sessions/show.html.haml)
#
#    #poster_hall
#      - pg = @poster_grid = Presentation::Poster::GRID.new
#      - @sessions.each do |s|
#        - color_tag = @sessions.index(s).modulo(12)
#        - pg.cssify(s.grids).each do |box_css|
#          = content_tag :a, "", :class => ["poster_row", "color_#{color_tag}"],
#                      :href => ksp(s),
#                      :style => "position:absolute;#{box_css}"
#      - pg.labels.each do |text, css|
#        = content_tag :div, text, :class => ["poster_row_top_label"],
#                      :style => "position:absolute;#{css}"
#
# Hopefully we shouldn't have to change the view for each conference.
#
class Session::Mappable < Session
end