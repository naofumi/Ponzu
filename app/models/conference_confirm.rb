## Module to confirm that the current conference 
## is valid.
#
# In multi-conference, we have to make sure that the objects
# are not inadvertently set to a different conference.
#
# To use this module, first define a #conference method that
# returns the conference object for this object.
# Secondly, create a named scope #in_conference that will
# scope AR finders on this object to the conference.
# Thirdly, include the ConferenceConfirm module.
#
# In the controller, whenever you want to search on this object, make sure
# that you include the #in_conference scope.
#
# Also, if you want to indirectly modify the conference (either
# using mass-assignment or modifing an associated object), you
# need to make sure that the #conference method points to the
# current_conference. You do this by  
#   obj.conference_confirm = current_conference.
# During validation, the AR model will confirm that the conference_confirm
# attribute has indeed been set, and is identical to the 
# result of the conference method.
#
# Note that assigning conference_confirm will not be necessary if you
# are directly assigning by
#   obj.conference = current_conference
# because there is no chance that the conference will be inadvertently changed.
#
# Below is an example
#
# # In authors.rb
#
#     ## Methods to confirm that the current conference 
#     ## is valid.
#     scope :in_conference, lambda {|conference|
#       includes(:submissions).  # includes instead of joins to make distinct
#       where(:submissions => {:conference_id => conference})
#     }
#
#     def conference
#       submissions.first.conference
#     end
#
#     include ConferenceConfirm
#
# # In authors_controller.rb
#
#    def index
#      @authors = Author.in_conference(current_conference).
#                        paginate(:page => params[:page])
#      respond_to do |format|
#        format.html # index.html.erb
#      end
#    end
# 
#     def create
#       @author = Author.new(params[:author])
#       @author.conference_confirm = current_conference
#
#       respond_to do |format|
#         if @author.save
#           flash[:notice] = "Author was successfully created"
#           if request.xhr?
#             format.js {js_redirect ksp(edit_author_path @author)}
#           else
#             format.html { redirect_to @author}
#           end
#         else
#           format.html { render action: "new" }
#         end
#       end
#     end
#
# Note that validation will only run if the conference_confirm
# attribute has been set.



module ConferenceConfirm
  def self.included(base)
    base.extend ClassMethods
    
    base.send :attr_accessor, :conference_confirm
    base.validate :conference_must_match_conference_confirm

    raise "#{base.to_s} must define #in_conference" unless base.methods.include?(:in_conference)
  end

  private

  def conference_must_match_conference_confirm
    if conference_confirm    
      raise "#{self.class.to_s} must define #conference" unless methods.include?(:conference)
      unless conference == conference_confirm 
        errors.add(:base, "Attribute conference_confirm did not match conference attribute.") 
      end
    end
  end

  module ClassMethods
  end

end