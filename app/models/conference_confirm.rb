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

## Update ##
#
# Now provides the 
#   validates_conference_identity *args
# method.
#
# For example, if we add
#   validates_conference_identity :submission, :author
# in the class definition, then a validation
# will be run that checks the value of submission.conference_tag
# author.conference_tag and self.conference_tag and confirms
# that they are identical.
#
# It can also be used in :has_many relationships like;
#   validates_conference_identity :users
#
module ConferenceConfirm
  def self.included(base)
    base.extend ClassMethods
    
    base.validate :conference_must_match_conference_confirm

    raise "#{base.to_s} must define #in_conference" unless base.methods.include?(:in_conference)
    base.instance_eval do
      def validates_conference_identity(*args)
        validate do 
          args.each do |attribute|
            objs = send(attribute)
            # The attribute may return an object that responds to #conference
            # or an Enumerable of objects that responds to #conference.
            # If the attribute returns something else, then we just ignore.
            # This is in most cases a simple nil value, and we'll leave it to
            # other validations to check for these.
            if objs.respond_to?(:conference)
              objs = [objs]
            end
            if objs.respond_to?(:each)
              objs.each do |obj|
                if obj.conference_tag != conference_tag
                  errors.add(:base, "#{attribute}.conference_tag (#{obj.conference_tag}) must match #{self.class}#conference_tag (#{conference_tag}).")
                end
              end
            end
          end
        end
      end
    end
  end

  # Before we introduced the conference_tag attribute on most of our tables,
  # we used conference_confirm to verify that the #conference result
  # matched the #conference_confirm result. We needed to do this because
  # we couldn't set the conference object directly for objects because
  # the conference was a value calculated through associations.
  #
  # Since we now have a #conference_tag for most of our tables, we now
  # use #conference_confirm= to directly set this value. This means that
  # we don't have to separately set #conference_tag=.
  #
  # As with the previous #conference_confirm= method, this should be called
  # any time we want to create a new object or update a previous one.
  #
  # We still keep the validation because we don't change the #conference_tag
  # if it is non-nil and we can't be sure that all tables will have a conference_tag
  # attribute in the future.
  def conference_confirm= conf_obj
    if has_attribute?(:conference_tag) && !conference_tag
      self.conference_tag = conf_obj.database_tag
    end
    @conference_confirm = conf_obj
    # TODO: Temporary hack until we remove #conference_id requirement from 
    # the database table
    if has_attribute?(:conference_id) && !conference_id
      self.conference_id = conf_obj.id
    end
  end

  def conference_confirm
    @conference_confirm
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