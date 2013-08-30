module PrivateMessageHelpers
  module Helpers
    
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
    end

    private

    def set_read_status_for_receipts
      if params[:receipts] && !params[:receipts].empty?
        receipts = Receipt.find(params[:receipts])
        Receipt.transaction do
          receipts.each do |r|
            r.update_attribute('read', true)
          end
        end
      end
    end
  end
end