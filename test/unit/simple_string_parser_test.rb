require 'test_helper'

class SimpleStringParserTest < ActiveSupport::TestCase

	test "split_by_top_level_parentheses should work with (" do
		string = "hello (there(bo)ad) find (me)"
		result = SimpleStringParser.new.split_by_top_level_parentheses(string)
		assert_equal [["hello", "there(bo)ad"], ["find", "me"]], result
	end
end