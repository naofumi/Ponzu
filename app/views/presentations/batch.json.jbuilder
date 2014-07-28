json.array! @presentations do |p|
  puts "Generate JSON for presentation #{p.id}"
  @presentation = p
  json.url presentation_url(@presentation)
  # json.json Jbuilder.encode{|json| json.partial! 'presentations/show'}
  json_as_string = JbuilderTemplate.encode(self) do |json_in_json|
    json_in_json.partial! 'presentations/show', :json => json_in_json
  end
  json.json json_as_string
end