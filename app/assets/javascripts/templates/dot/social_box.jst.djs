<div class="social_box" data-ajax="/presentations/{{= it.presentation_id }}/social_box" data-expiry="{{= it.expiry }}" id="presentation_{{= it.presentation_id }}_social_box">
	{{? it.user_id }}
		<div class="like_box">
			<div class="like" id="like_button_{{= it.presentation_id }}">
				{{= it.like_button }}
			</div>
		</div>
		{{? it.voter }}
			<div class="vote_box">
				<div class="like" id="vote_button_{{= it.presentation_id }}">
					<span class="social_controls">
						<form accept-charset="UTF-8" action="/likes/vote" class="new_like" data-invalidates-keys="/presentations/{{= it.presentation_id }}/social_box like_highlights list_highlights likes/(.+/)?my" data-ks-insert-response="" data-remote="true" id="presentation_{{= it.presentation_id }}_new_like" method="post">
							<div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="✓"></div>
							<input id="presentation_{{= it.presentation_id }}_like_presentation_id" name="like[presentation_id]" type="hidden" value="{{= it.presentation_id }}">
							<span>
								<input {{? it.score === 1 }}checked{{?}} id="presentation_{{= it.presentation_id }}_like_score_1" name="like[score]" type="radio" value="1">
								<label for="presentation_{{= it.presentation_id }}_like_score_1">Excellent!</label>
							</span>
							<span>
								<input {{? it.score === 2 }}checked{{?}} id="presentation_{{= it.presentation_id }}_like_score_2" name="like[score]" type="radio" value="2">
								<label for="presentation_{{= it.presentation_id }}_like_score_2">Unique!</label>
							</span>
							<span>
								<input {{? it.score === 0 }}checked{{?}} id="presentation_{{= it.presentation_id }}_like_score_0" name="like[score]" type="radio" value="0">
								<label for="presentation_{{= it.presentation_id }}_like_score_0">No Vote</label>
							</span>
						</form>
					</span>
				</div>
			</div>
		{{?}}
	{{?}}
</div>
{{= it.modify_div}}
