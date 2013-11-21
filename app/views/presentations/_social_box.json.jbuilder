# Cache keys are the @presentation, current_user and
# anything that changes any Like belonging to the @presentation (incl. other users)
# so that we can update counts.
#
# We don't share the cache between different users because we
# would have to specify each single attribute of User which
# changes how the social box is displayed, which is possible, but tough.
#
# TODO: We currently user Like.where(:presentation_id => ...) because we want to be
# sure that we are collecting all descendants. We need to clean up the Like class
# notation, so that we can be confident about what @presentation.likes would mean.
# (will it include all descendants of Like?)
#
# all_likes = Like.where(:presentation_id => @presentation)
# Cache keys @presentation.id,
#            all_likes.any? && all_likes.max_by{|p| p.updated_at}.updated_at
#            current_user && current_user.id

all_likes = Like.in_conference(current_conference).where(:presentation_id => @presentation)

json.cache! ["v1", current_conference, I18n.locale, 
             "presentations/social_box", 
             @presentation.id, 
             all_likes.any? && all_likes.max_by{|p| p.updated_at}.updated_at,
             all_likes.size,
             current_user && current_user.id] do
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
    json.secret like && like.is_secret
    json.scheduled like.kind_of?(Like::Schedule)
    json.likes_count @presentation.likes.where(:is_secret => false).size
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
end