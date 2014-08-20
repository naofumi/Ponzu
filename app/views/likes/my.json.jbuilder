json.array! @likes do |like|
  json.like_id like.id
  json.presentation_id like.presentation_id
end
