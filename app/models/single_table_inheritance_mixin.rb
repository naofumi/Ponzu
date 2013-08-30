# This mixin helps to solve some issues surrounding single-table inheritance.
#
# Notes on Single Table Inheritance
# http://www.christopherbloom.com/2012/02/01/notes-on-sti-in-rails-3-0/
# http://www.alexreisner.com/code/single-table-inheritance-in-rails
#
# This mixin currently changes behavior of the includee class as follows;
#
# 1. A validator is added which ensures that any new records will have
#    the +type+ value correctly set to a descendant of the current class.
# 2. Changes the #model_name to point to superclass#model_name. #model_name
#    is used in url_for(@presentation). Since we won't create controllers
#    and routes for each subclass, but we will rather use the controller
#    for the base class (i.e. no presentation_booths_path, presentation_exhibitions_path
#    Instead we will use presentations_path).
module SingleTableInheritanceMixin
  def self.included(base)
    base.extend ClassMethods
    
    # Sometimes we want to change the class of an object.
    # We can do this in STI by simply changing the +type+ field.
    # This validation ensures that the new +type+ stays within
    # the subclasses of the base model, and hence that the new +type+
    # can still work with the table.
    base.validate do |obj|
      base_model = obj.class.model_name.constantize
      if obj.type && !base_model.descendants.map{|c| c.name}.include?(obj.type.to_s)
        obj.errors[:type] << " #{obj.type} must be a valid subclass of #{base_model}" 
      end
    end
  end

  module ClassMethods
    def inherited(child)
      child.instance_eval do
        alias :original_model_name :model_name
        # Our STI subclasses will be routed through to the parent routes
        def model_name
          superclass.model_name
        end
      end
      super
    end
  end
end