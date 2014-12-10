# Include this into evey object that should be managed seperately
# for each conference. 
#
# 1. It ensures that :conference_tag is set as a database field.
# 2. It also provides the :in_conference query scope.
# 3. It provides :infer_conference_from so that the conference_tag 
#    can be set automatically.
module ConferenceRefer
  def self.included(base)
    base.extend ClassMethods
    
    base.instance_eval do

      validates_presence_of :conference_tag
      attr_protected :conference_tag

      scope :in_conference, lambda {|conference|
        where(:conference_tag => conference.database_tag)
      }
      
      # Set conference_tag to that of first argument that
      # responds_to :conference.
      def infer_conference_from *args
        # This is necessary when we
        # creating join table objects indirectly
        # using a has_many :through relation
        # and we use the join table objects to
        # validate conference identity.
        after_initialize do
          set_conference_tag_if_unset args
        end

        before_validation do
          set_conference_tag_if_unset args
        end
      end

      include ConferenceConfirm

    end
  end
  
  def conference
    @conference ||= Conference.where(:database_tag => conference_tag).first!
  end

  module ClassMethods
  end

  private

  def set_conference_tag_if_unset(args)
    # If we have used a #select scope, then the returned object
    # might not have a :conference_tag attribute. In that
    # case, we just ignore because we probably won't
    # update or create objects based on this one.
    return unless has_attribute?(:conference_tag)
    return if !conference_tag.blank?
    
    args.each do |arg|
      objs = send(arg)
      if objs.respond_to?(:conference)
        objs = [objs]
      end
      if objs.respond_to?(:each)
        objs.each do |obj|
          self.conference_tag = obj.conference.database_tag
          break
        end
      end
      # if ojbs does not respond to :conference nor to :each
      # then it probably is nil. We ignore these cases and
      # leave conference_tag as blank.
    end
  end

end