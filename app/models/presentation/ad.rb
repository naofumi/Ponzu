# Represents an Advertisment.
#
# Has an ad_category attribute used to determine
# what pages this ad will be shown on.
class Presentation::Ad < Presentation
  attr_accessible :ad_category

end