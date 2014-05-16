<div id="presentation_{{= it.presentation_id }}_comments">
  <form accept-charset="UTF-8" action="/comments" class="new_comment" data-invalidates-keys="/presentations/{{= it.presentation_id }}/comments" data-ks-insert-response="" data-remote="true" id="new_comment" method="post">
    <div style="margin:0;padding:0;display:inline">
      <input name="utf8" type="hidden" value="✓">
    </div>  
    <input id="comment_presentation_id" name="comment[presentation_id]" type="hidden" value="{{= it.presentation_id }}">
    <input id="comment_parent_id" name="comment[parent_id]" type="hidden">
    <textarea id="comment_text" name="comment[text]" placeholder="Write your comment here."></textarea>
    <br>
    <button class="comment_submit button icon comment" name="button" type="submit">Submit comment</button>
  </form>
  {{~ it.comments :comment:index}}
    <div class='comment comment_box depth_{{= comment.depth }}' data-container="presentations_{{= it.presentation_id }}_comments" id="comment_{{= comment.id }}">
      <div class='comment_header'>
        <div class='time_box'>
          <span style="margin-right:10px;">{{= comment.created_at }}</span>
          <a href="/comments/{{= comment.id }}/reply" class="button comment icon" data-remote=true data-ks-insert-response=true>Reply</a>
        </div>
        <a href="#!_/users/{{= comment.user_id}}">{{= comment.user_name}}</a>
        {{? comment.is_author }}
          <span>author</span>
        {{?}}
      </div>
      <div style="clear:both">
        {{= comment.text }}
        <div class="close_box">
          {{? it.user_id == comment.user_id && comment.is_leaf }}
            <a href="/comments/{{= comment.id }}" data-method="delete" data-remote=true data-confirm="Are you sure you want to delete this comment?" rel="nofollow" data-invalidates-keys="/presentations/{{= it.presentation_id }}/comments" data-ks-insert-response=true class="button icon trash">delete comment</a>
          {{?}}
        </div>
      </div>
      <div id="reply_to_{{= comment.id}}"></div>
    </div>
  {{~}}
</div>

<form accept-charset="UTF-8" action="/comments" class="new_comment" data-invalidates-keys="/presentations/{{= it.presentation_id }}/comments" data-ks-insert-response="" data-remote="true" id="new_comment" method="post"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="✓"><input name="authenticity_token" type="hidden" value="fGy3fqsDr9uTCHb60b5BEW3DDQl15qAmuApv2PdzLAI="></div>  <input id="comment_user_id" name="comment[user_id]" type="hidden">
  <input id="comment_presentation_id" name="comment[presentation_id]" type="hidden" value="{{= it.presentation_id }}">
  <input id="comment_parent_id" name="comment[parent_id]" type="hidden">
  <textarea id="comment_text" name="comment[text]" placeholder="Write your comment here."></textarea>
  <br>
  <button class="comment_submit button icon comment" name="button" type="submit">Submit comment</button>
</form>