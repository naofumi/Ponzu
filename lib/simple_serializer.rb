# Provides alternative to the ActiveRecord::AttributeMethods::Serialization.serialize method.
#
# Objects using ActiveRecord::serialize always updates, even if the contents haven't
# changed. This is because +serialize+ cannot be reliably notified if the value
# of the serialized attribute changes (i.e. if a single element of an array changes).
#
# Since always updating is a big problem, we provide a much simpler hack that
# doesn't cause updates. It only updates when the attribute is explicitly updated
# with 
#   [attribute] = value
#
# We currently only support very simple attributes:
#
# <b>serialize_array [attribute](, :class => [class name])(, :typecaster => [typecasting callback])</b>
#
# Serialize an attribute. The default value for the attribute will be
# an empty array; hence you should use it when your input value is an array.
#
# Provide +:class+ if you want to convert each
# element into a specific object (otherwise, it will be a JSON primitive).
#
# Provide +:typecaster+ if you want to coerce the input value. For example,
# if you want to convert +"1"+ (String) to +1+ (Integer). This is necessary 
# because HTTP request parameters only return strings. ActiveRecord coerces
# these values to match the database field types, but we can't do that in SimpleSerializer.
# 
# The argument to +:typecaster+ is a symbol to a callback function. The
# callback function is a filter that takes the input and converts it to 
# the suitable form. We only do this in the input, because if the input
# is OK, then we shouldn't have to change stuff on the output.
#
# Provide +:sort:+ with a Proc if you want to sort the output of the getter.
# +:sort => Proc.new{|a, b| b <=> a}+
module SimpleSerializer
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def serialize_array(attribute, options = {})
      object_class = options[:class] && options[:class].constantize
      typecaster = options[:typecaster]
      sort_block = options[:sort]

      define_method attribute do
        serialized = read_attribute(attribute)
        result = SimpleSerializer::unserialize_array(serialized, :class => object_class)
        if sort_block
          result.sort(&sort_block)
        else
          result
        end
      end

      define_method "#{attribute}=".to_sym do |array_of_objects|
        if typecaster
          array_of_objects = send(typecaster, array_of_objects)
        end
        write_attribute(attribute, 
                        SimpleSerializer::serialize_array(array_of_objects))
      end
    end

    def serialize_single(attribute, options = {})
      object_class = options[:class] && options[:class].constantize
      typecaster = options[:typecaster]
      sort_block = options[:sort]

      define_method attribute do
        serialized = read_attribute(attribute)
        result = SimpleSerializer::unserialize_array(serialized, :class => object_class)
        result.first
      end

      define_method "#{attribute}=".to_sym do |object|
        if typecaster
          object = send(typecaster, object)
        end
        write_attribute(attribute, 
                        SimpleSerializer::serialize_array([object]))
      end      
    end
  end

  def self.unserialize_array(serialized, options = {})
    return [] if serialized.blank?
    result = []
    objectified = ActiveSupport::JSON.decode(serialized)
    if options[:class]
      objectified.each do |params|
        result << options[:class].new(params)
      end
    else
      result = objectified
    end
    result
  end

  def self.serialize_array(objects)
    objects = [] unless objects
    ActiveSupport::JSON.encode(objects) # Don't add class name in root.
  end
end