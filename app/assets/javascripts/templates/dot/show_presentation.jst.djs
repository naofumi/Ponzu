<div class="" data-container-ajax="/ponzu_frame" data-container="ponzu_frame" data-expiry="{{= it.expiry }}" id="show_presentation_{{= it.id }}" data-title="{{= it.number }}: {{= it.header_title}}">
  <div class="presentation panel">
    <div class="presentation_header">
      <span>
        <a href="#!_/sessions/{{= it.session.id }}" class="button arrowleft icon">{{= it.session.number }}</a>
      </span>
      <span>
        <a href="#!_/rooms/{{= it.room.id }}" class="button pin icon">{{= it.room.name}} (Map)</a>
      </span>
    </div>
    <div class="prev_next_navigation">
      <a href="#!_/presentations/{{= it.previous_id}}" class="arrow left" {{? !it.previous_id }}style="visibility:hidden"{{?}}></a>
      <a href="#!_/presentations/{{= it.next_id}}" class="arrow right" {{? !it.next_id }}style="visibility:hidden"{{?}}></a>
    </div>
    <div style="clear:both"></div>
  </div>
  <div class="presentation panel" id="presentation_detail_{{= it.id}}">
    <span class="number">
      {{= it.number }}
      {{? it.other_numbers.length > 0 }}
        <span class="same_presentations">({{= it.other_numbers.join(', ')}})</span>
      {{?}}
    </span>
    {{? it.can_edit }}<a href="#!_/submissions/{{= it.submission_id }}/edit">[edit]</a>{{?}}
    <span class="time">
      {{= it.starts_at }}
    </span>
    {{? !it.cancel }}
      <h1>{{= it.title }}</h1>
      <div class="authors">
        {{~ it.authorships :authorship:index}}
          <span class="author_{{= authorship.author_id}}">{{? authorship.is_presenting_author }}○{{?}}<a href="#!_/authors/{{= authorship.author_id}}">{{= authorship.name}}</a>{{? index != (it.authorships.length - 1)}},{{?}}<sup>{{= authorship.affiliations.join(',') }}</sup></span>
        {{~}}
      </div>
      <div class="institutions">
        {{~ it.institutions :institution:index}}
          <div>
            <sup>{{= index + 1 }}</sup>
            {{= institution.name }}
          </div>
        {{~}}
      </div>
      <h3>SUMMARY</h3>
      {{ abstractClass = (it.disclose_abstract ? "text auto-hypen" : ""); }}
      <div id="abstract" class="{{= abstractClass }}">
        {{= it.abstract }}
      </div>
    {{??}}
      <h1>Cancelled</h1>
    {{?}}
  </div>
  {{? !it.cancelled }}
    <div class="presentation panel">
      <div data-ajax="/presentations/{{= it.id}}/social_box" data-expiry="86400" id="presentation_{{= it.id}}_social_box"></div>
    </div>
    <div class='panel_title no_print'>COMMENTS</div>
      <div class='presentation panel no_print'>
        <div id='comments'>
          <div class="" data-ajax="/presentations/{{= it.id}}/comments" data-expiry="86400" id="presentation_{{= it.id}}_comments">
        </div>
      </div>
    </div>
    {{? it.same_submission.length > 0}}
      <div class="panel_title no_print">Same submission</div>
      <div class="panel paneled_list no_print">
        {{~ it.same_submission :presentation_id:index }}
          <a href="#!_/presentations/{{= presentation_id }}">
            <div class="presentation" data-ajax="/presentations/{{= presentation_id }}/heading" data-expiry="86400" id="session_details_presentation_{{= presentation_id}}"></div>
          </a>
        {{~}}      
      </div>
    {{?}}
    <div class="panel_title">Keywords</div>
    <div class="panel">
      {{~ it.keywords :keyword:index }}
        <a href="#!_/search?query={{= encodeURIComponent(keyword) }}">{{= keyword}}</a>
        {{? index != (it.keywords.length - 1)}}, {{?}}
      {{~}}
    </div>

    <div class="panel_title no_print">Other presentations by same authors</div>
    <div class="panel paneled_list no_print">
      {{~ it.same_authors :presentation_id:index }}
        <a href="#!_/presentations/{{= presentation_id }}">
          <div class="presentation" data-ajax="/presentations/{{= presentation_id }}/heading" data-expiry="86400" id="session_details_presentation_{{= presentation_id}}"></div>
        </a>
      {{~}}      
    </div>

    <div class="panel_title no_print">More like this <i>(experimental)</i></div>
    <div class="panel paneled_list no_print">
      {{~ it.more_like_this :presentation_id:index }}
        <a href="#!_/presentations/{{= presentation_id }}">
          <div class="presentation" data-ajax="/presentations/{{= presentation_id }}/heading" data-expiry="86400" id="session_details_presentation_{{= presentation_id}}"></div>
        </a>
      {{~}}      
    </div>
    <script>
      {{= it.javascript }}
    </script>
  {{?}}
</div>