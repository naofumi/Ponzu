module Kamishibai
  module Menu
    
    def self.included(base)
      base.helper_method :set_menu
      base.extend(ClassMethods)
    end

    module ClassMethods
      def default_menu(menu)
        before_filter do
          @menu = menu
        end
      end
    end

    def set_menu(menu)
      @menu = menu
    end
  end
end