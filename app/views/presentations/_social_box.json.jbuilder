json.renderer do
  json.library "dot"
  json.template "social_box"
  json.expiry (@expiry || Kamishibai::Cache::DEFAULT_EXPIRY)
end
if current_user
	json.presentation_id @presentation.id
	json.user_id current_user && current_user.id
	json.like_button render(:partial => 'likes/like_button', :formats => [:html],
	                        :locals =>{ :presentation => @presentation })
	json.voter can?(:vote, Like)
	vote = @vote || 
	       current_user.votes.detect{|v| v.presentation_id == @presentation.id } || 
	       current_user.votes.build(:presentation_id => @presentation.id)
	json.score vote.score
  # Highlight liked
  css_class = [("scheduled" if schedule_for_current_user_and_presentation(@presentation)),
                 ("liked" if like_for_current_user_and_presentation(@presentation))].compact
  remove_css_class = ["scheduled", "liked"] - css_class
  json.modify_div ks_modify_elements "session_details_presentation_#{@presentation.id}" => {add_class: css_class.join(' '),
                                                                              remove_class: remove_css_class.join(' ')}
end
