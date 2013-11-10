json.renderer do
  json.library "dot"
  json.template "templates/dot/social_box"
  json.expiry (@expiry || Kamishibai::Cache::DEFAULT_EXPIRY)
end
if current_user
	json.presentation_id @presentation.id
	json.user_id current_user.id

  like = like_for_current_user_and_presentation(@presentation)
  json.like_id like && like.id
  json.scheduled like.kind_of?(Like::Schedule)
  json.likes_count @presentation.likes.size
  like ||= @presentation.likes.build # We always need a like object to calculate invalidated_paths
  json.invalidated_paths invalidated_paths(like)

  comments = @presentation.comments
  json.comments_count comments.inject(comments.size){|memo, c| memo + c.child_count.to_i}
  # json.like_button render(:partial => 'likes/like_button', :formats => [:html],
  #                         :locals =>{ :presentation => @presentation })

	json.voter can?(:vote, Like)
	vote = @vote || 
	       current_user.votes.detect{|v| v.presentation_id == @presentation.id } || 
	       current_user.votes.build(:presentation_id => @presentation.id)
	json.score vote.score
  # Highlight liked
  # css_class = [("scheduled" if schedule_for_current_user_and_presentation(@presentation)),
  #                ("liked" if like_for_current_user_and_presentation(@presentation))].compact
  # remove_css_class = ["scheduled", "liked"] - css_class
  # json.modify_div ks_modify_elements "session_details_presentation_#{@presentation.id}" => {add_class: css_class.join(' '),
  #                                                                             remove_class: remove_css_class.join(' ')}
end
