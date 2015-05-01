# This mixin adds some methods to assist with batch import.
#
module BatchImportMixin
  def self.included(base)
    base.extend ClassMethods

    # Define an attribute that tells the object that it 
    # is being batch imported.
    #
    # In the batch import routine, we will set `batch_import = true`.
    # Then, in the model, we will use the following to exclude some validations
    # during the batch import process.
    # 
    # validate :some_validations, :unless => :batch_import
    base.send :attr_accessor, :batch_import    
  end

  module ClassMethods
  end
end