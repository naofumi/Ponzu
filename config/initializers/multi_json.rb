require 'json'
module MultiJson
  module Adapters
    class JsonGem
      def self.dump(object, options={})
        # #to_json encodes UTF-8 strings, which I don't want.

        # object.to_json(process_options(options))
        JSON.dump(object)
      end
    end
  end
end
