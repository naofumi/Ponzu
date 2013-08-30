# Parser to analyze the strings that we couldn't manage with 
# simple regular expressions.
#
# In the future, we might have to study real parsers.
# http://treetop.rubyforge.org/index.html
class SimpleStringParser

	# Manage strings like "hello (there(bo)ad) find (me)"
	def split_by_top_level_parentheses(string)
		result = []
		in_string = ""
		out_string = ""
		depth = 0
		is_in = false
		string.each_char do |char|
			if is_in # in
				if char == ')' && depth == 1
					# move out and push into results
					result << [out_string.strip, in_string.strip]
					depth = 0
					in_string, out_string = "", ""
					is_in = false
				elsif char == '('
					depth += 1
					in_string << char
				elsif char == ')'
					depth -= 1
					in_string << char
				else
					in_string << char
				end
			else # out
				if char == '('
					is_in = true
					depth += 1
				else
					out_string << char
				end
			end
		end
		result
	end
end