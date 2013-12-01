<div data-container-ajax="/ponzu_frame" data-container="ponzu_frame" data-expiry="{{= it.expiry }}" id="show_presentation_{{= it.id }}" data-title="{{= it.number }}: {{= it.header_title}}">
  <div class="presentation panel {{= it.type }}">
    <div class="presentation_header">
      <span>
        <a href="#!_/sessions/{{= it.session.id }}" class="button arrowleft icon">{{= it.session.number }}</a>
      </span>
      {{? !(it.type == 'presentation_ad')}}
        {{? it.room && it.room.id }}
          <span>
            <a href="#!_/rooms/{{= it.room.id }}" class="button pin icon">{{= it.room.name}}</a>
          </span>
        {{?}}
        <span>
          <a href="#!_{{= it.poster_timetable_path }}" onclick="KSScrollMemory.set({href: {{= '/' + it.poster_timetable_path }}, elementId: 'session_{{= it.id }}'})" class="button icon pin">
            {{? (it.type == 'presentation_poster' || it.type == 'presentation_booth')}}
              Map
            {{??}}
              Timetable
            {{?}}
          </a>
        </span>
      {{?}}

    </div>
    <div class="prev_next_navigation">
      <a href="#!_/presentations/{{= it.previous_id}}" class="arrow left" {{? !it.previous_id }}style="visibility:hidden"{{?}}></a>
      <a href="#!_/presentations/{{= it.next_id}}" class="arrow right" {{? !it.next_id }}style="visibility:hidden"{{?}}></a>
    </div>
    <div style="clear:both"></div>
  </div>
  <div class="presentation panel {{= it.type }}" id="presentation_detail_{{= it.id}}">
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
      <h1 style="clear:both">{{= it.title }}</h1>
      <div class="authors">
        {{~ it.authorships :authorship:index}}
          <span class="author_{{= authorship.author_id}}">{{? authorship.is_presenting_author }}○{{?}}<span class="heart">&nbsp;</span><span class="club_out">&nbsp;</span><span class="club_in">&nbsp;</span><a href="#!_/authors/{{= authorship.author_id}}">{{= authorship.name}}</a>{{? index != (it.authorships.length - 1)}},{{?}}<sup>{{= authorship.affiliations.join(',') }}</sup></span>
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
      {{? it.external_link }}
        <div class="paneled_list">
          <a href="{{= it.external_link }}" target="external">Link for more Information</a>
        </div>
      {{?}}
      <div style="text-align:right">
        {{? it.email }}
          <span class="corresponding_email">
            <a href="mailto:{{= it.email}}">{{= it.email}}</a>
          </span>
        {{?}}
        {{? it.speech_language }}
          <span class="speech_language">
            {{= ViewHelper.speechLanguageIndicator(it.speech_language) }}
          </span>
        {{?}}
      </div>
    {{??}}
      <h1>Cancelled</h1>
    {{?}}
  </div>
  {{? it.art }}
    <a href="{{= it.art}}"><img src="{{= it.art}}" style="width: 100%" class="art"></a>
  {{?}}
  {{? !it.cancelled }}
    {{? it.user_id }}
      <div class="presentation panel">
        <div data-ajax="/presentations/{{= it.id}}/social_box" data-expiry="86400" id="presentation_{{= it.id}}_social_box"></div>
      </div>
      <div class='panel_title no_print comments {{= it.type }}'>COMMENTS</div>
        <div class='presentation panel no_print comments {{= it.type }}'>
          <div id='comments'>
            <div class="" data-ajax="/presentations/{{= it.id}}/comments" data-expiry="86400" id="presentation_{{= it.id}}_comments">
          </div>
        </div>
      </div>
    {{?}}
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

    {{? it.keywords.length > 0}}
      <div class="panel_title">Keywords</div>
      <div class="panel">
        {{~ it.keywords :keyword:index }}
          <a href="#!_/search?query={{= encodeURIComponent(keyword) }}">{{= keyword}}</a>{{? index != (it.keywords.length - 1)}}, {{?}}
        {{~}}
      </div>
    {{?}}

    {{? it.ads.length > 0}}
      <div class="panel_title no_print">Advertisements</div>
      <div class="panel paneled_list no_print">
        {{~ ViewHelper.randomSelect(it.ads, 3) :presentation_id:index }}
          <a href="#!_/presentations/{{= presentation_id }}">
            <div class="presentation" data-ajax="/presentations/{{= presentation_id }}/heading" id="session_details_presentation_{{= presentation_id}}"></div>
          </a>
        {{~}}
      </div>
    {{?}}

    {{? it.same_authors.length > 0}}
      <div class="panel_title no_print">Other presentations by the same authors</div>
      <div class="panel paneled_list no_print">
        {{~ it.same_authors :presentation_id:index }}
          <a href="#!_/presentations/{{= presentation_id }}">
            <div class="presentation" data-ajax="/presentations/{{= presentation_id }}/heading" data-expiry="86400" id="session_details_presentation_{{= presentation_id}}"></div>
          </a>
        {{~}}      
      </div>
    {{?}}

    {{? it.more_like_this.length > 0}}
      <div class="panel_title no_print more_like_this {{= it.type }}">More like this <i>(experimental)</i></div>
      <div class="panel paneled_list no_print more_like_this {{= it.type }}">
        {{~ it.more_like_this :presentation_id:index }}
          <a href="#!_/presentations/{{= presentation_id }}">
            <div class="presentation" data-ajax="/presentations/{{= presentation_id }}/heading" data-expiry="86400" id="session_details_presentation_{{= presentation_id}}"></div>
          </a>
        {{~}}      
      </div>
    {{?}}
    <script>
      {{= it.javascript }}
    </script>
  {{?}}
</div>