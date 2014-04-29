# Includes everything that needs a quick expiry.
# That is everything social and also includes author flags.
#
# Cache keys are the @presentation, current_user and
# anything that changes any Like belonging to the @presentation (incl. other users)
# so that we can update counts.
#
# Since we now also change author flags, we also add @presentation.authors to the 
# keys.
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

all_likes = ::Like::Like.in_conference(current_conference).where(:presentation_id => @presentation)

json.cache! ["v2", current_conference, I18n.locale, 
             "presentations/social_box/json", 
             @presentation.id, 
             all_likes.any? && all_likes.max_by{|p| p.updated_at}.updated_at,
             all_likes.size,
             @presentation.authors, # If any of the authors' users has changed a flag
             current_user] do
  json.renderer do
    json.library "dot"
    json.template "templates/dot/social_box"
    json.expiry (@expiry || Kamishibai::Cache::DEFAULT_EXPIRY)
  end
  if current_user

    # Stuff that depends on current_user
  	json.logged_in !!current_user

    like = current_user && all_likes.detect{|l| l.user_id == current_user.id}
    json.like_id like && like.id
    json.secret like && like.is_secret
    json.scheduled like.kind_of?(Like::Schedule)


    if can?(:vote, Like)
      json.voter can?(:vote, Like)
      vote = @vote || 
             current_user.votes.detect{|v| v.presentation_id == @presentation.id } || 
             current_user.votes.build(:presentation_id => @presentation.id)
      json.score vote.score
    end

    # stuff that doesn't depend on current_user
    authors = @presentation.authors
    json.cache! ["v1", current_conference, I18n.locale,
                 "presentations/social_box/json/fixed",
                 @presentation.id,
                 all_likes.any? && all_likes.max_by{|p| p.updated_at}.updated_at,
                 all_likes.size,
                 authors] do
      json.presentation_id @presentation.id
      json.likes_count all_likes.select{|l| l.is_secret == false}.size
      like ||= @presentation.likes.build # We always need a like object to calculate invalidated_paths
      json.invalidated_paths invalidated_paths(like)
      comments = @presentation.comments
      json.comments_count comments.inject(comments.size){|memo, c| memo + c.child_count.to_i}

      author_styles = authors.inject(Hash.new) do |memo, a|
        memo[a.id] = []
        memo[a.id] << :looking_for_job if a.looking_for_job?
        memo[a.id] << :looking_for_person if a.looking_for_person?
        memo[a.id] << :looking_for_partner if a.looking_for_partner?
        memo
      end
      json.author_styles do
        author_styles.each do |id, classes|
          next if classes.empty?
          json.set! "author_#{id}", classes
        end
      end
    end
  end
end