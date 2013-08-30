require 'test_helper'

class GlobalMessageTest < ActiveSupport::TestCase
	def setup
		@global_message = global_messages(:generic_global_message)
	end

	test "must refer to a conference" do
    assert_equal conferences(:generic_conference), @global_message.conference
  end
end
