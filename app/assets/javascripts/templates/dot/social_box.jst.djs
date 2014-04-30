<div class="social_box" data-ajax="/presentations/{{= it.presentation_id }}/social_box" data-expiry="{{= it.expiry }}" id="presentation_{{= it.presentation_id }}_social_box">
	{{? it.logged_in }}
		<div class="like_box">
			<div class="social_stats">
				{{? it.comments_count > 0}} {{= it.comments_count }} comments{{?}}
				{{? it.likes_count > 0}}
				  {{= it.likes_count }} likes&nbsp;
					<a href="/presentations/{{= it.presentation_id }}/likes" class="button icon arrowright" style="padding: 0.2em 0.7em;" data-ks-insert-response=true data-remote=true>view likes</a>
				{{?}}
			</div>
			<div class="list_likes" id="likes_presentation_{{= it.presentation_id}}"></div>
			<div class="like" id="like_button_{{= it.presentation_id }}">
				<span class="social_controls">
					{{? it.like_id }}				
						{{? it.scheduled }}
						  <a href="/likes/{{= it.like_id }}/unschedulize" class="button icon clock" data-invalidates-keys="{{= it.invalidated_paths }}" data-ks-insert-response data-method="put" data-remote="true" rel="nofollow">remove {{= it.secret ? 'secret ' : ''}} schedule</a>
						  {{? it.secret }}
							  <a href="/likes/{{= it.like_id }}/secretify?revoke=1" class="button icon like" data-invalidates-keys="{{= it.invalidated_paths }}" data-ks-insert-response data-method="put" data-remote="true" rel="nofollow">like</a>
							{{??}}
							  <a href="/likes/{{= it.like_id }}/secretify" class="button icon like" data-invalidates-keys="{{= it.invalidated_paths }}" data-ks-insert-response data-method="put" data-remote="true" rel="nofollow">unlike (make secret)</a>
							{{?}}
						{{??}}
						  <a href="/likes/{{= it.like_id }}/schedulize" class="button icon clock" data-invalidates-keys="{{= it.invalidated_paths }}" data-ks-insert-response data-method="put" data-remote="true" rel="nofollow" title="Secret Likes and Secret Schedules are invisible from the authors.">add to {{= it.secret ? 'secret ' : ''}}schedule</a>
						  <a href="/likes/{{= it.like_id }}" class="button icon like" data-invalidates-keys="{{= it.invalidated_paths }}" data-ks-insert-response data-method="delete" data-remote="true" rel="nofollow">{{= it.secret ? 'secret ' : ''}}unlike</a>
						{{?}}
					{{??}}
					  <a href="/likes?like%5Bpresentation_id%5D={{= it.presentation_id }}" class="button icon like" data-invalidates-keys="{{= it.invalidated_paths }}" data-ks-insert-response data-method="post" data-remote="true" rel="nofollow">like</a>
					  <a href="/likes?like%5Bpresentation_id%5D={{= it.presentation_id }}&like%5Bis_secret%5D=1" class="button icon like" data-invalidates-keys="{{= it.invalidated_paths }}" data-ks-insert-response data-method="post" data-remote="true" rel="nofollow" title="Secret Likes and Secret Schedules are invisible from the authors.">secret like</a>
					{{?}}
				</span>
			</div>
		</div>
		{{? it.voter && it.votable }}
			<div class="vote_box">
				<div class="like" id="vote_button_{{= it.presentation_id }}">
					<span class="social_controls">
						<form accept-charset="UTF-8" action="/likes/vote" class="new_like" data-invalidates-keys="/presentations/{{= it.presentation_id }}/social_box like_highlights list_highlights likes/(.+/)?my" data-ks-insert-response="" data-remote="true" id="presentation_{{= it.presentation_id }}_new_like" method="post">
							<div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="✓"></div>
							<input id="presentation_{{= it.presentation_id }}_like_presentation_id" name="like[presentation_id]" type="hidden" value="{{= it.presentation_id }}">
							{{~ it.scores :score:index}}
								<span>
									<input {{? it.score === score }}checked{{?}} id="presentation_{{= it.presentation_id }}_like_score_{{= score }}" name="like[score]" type="radio" value="{{= score }}">
									<label for="presentation_{{= it.presentation_id }}_like_score_{{= score }}">{{= it.score_labels[score] }}</label>
								</span>
							{{~}}
						</form>
					</span>
				</div>
			</div>
		{{?}}
	{{?}}
</div>
{{ 
	var addClass = [];
	var removeClass = [];
	var addClassString = "";
	var removeClassString = "";
	if(it.like_id) {
		addClass.push("liked");
  } else {
    removeClass.push("liked");
  }
  if (it.scheduled) {
  	addClass.push("scheduled");
	} else {
		removeClass.push("scheduled");
  }
	addClassString = addClass.join(' ');
	removeClassString = removeClass.join(' ');
}}
<div data-add-class="{{= addClassString }}" data-attributes-only=true data-remove-class="{{= removeClassString }}" id="session_details_presentation_{{= it.presentation_id}}"></div>
<div data-add-class="{{= addClassString }}" data-attributes-only=true data-remove-class="{{= removeClassString }}" id="presentation_detail_{{= it.presentation_id}}"></div>
{{
	for (var key in it.author_styles) {
		classes = it.author_styles[key];
		var authorElements = document.querySelectorAll('.' + key);
		for (var i = 0; i < authorElements.length; i++) {
		  var author = authorElements[i];
		  for (var c = 0; c < classes.length; c++) {
		    kss.addClass(author, classes[c]);
		  };
		};
	}
}}