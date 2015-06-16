<div class="program orals {{= it.type }}" data-container-ajax="/ponzu_frame" data-container="ponzu_frame" data-title="{{= it.head_title }}" id="session_detail_{{= it.id }}">
  <div class="panel session_header">
    {{? it.type != 'session_ad'}}
      <div class="number">
        {{= it.number }}
        {{? it.can_edit }}<a href="#!_/sessions/{{= it.id }}/edit">[edit]</a>{{?}}
      </div>
      <div class="time">
        <a href="#!_{{= it.poster_timetable_path }}" onclick="KSScrollMemory.set({href: {{= '/' + it.poster_timetable_path }}, elementId: 'session_{{= it.id }}'})" class="button icon clock">
          {{= it.starts_at }} - {{= it.ends_at }}
        </a>
      </div>
      {{? it.room && it.room.id }}
        <div class="room">
          <a href="#!_/rooms/{{= it.room.id }}" class="button icon pin">{{= it.room.name }}</a>
        </div>
      {{?}}
    {{?}}
    <div class="title">
      {{= it.title }}
    </div>
    {{? it.organizers && it.organizers.length > 0 }}
      <div class="chairs">
        <span class="label">Chairs</span>
        <div>
          {{= it.organizers.join('<br />') }}
        </div>
      </div>
    {{?}}
    {{? it.text }}
      <div id="summary_description" class="summary_description {{= it.show_text ? 'show' : ''}}">
        {{= it.text }}
      </div>
      {{? !it.show_text }}
        <div class="show_summary_button_wrapper {{= it.show_text ? 'hide' : ''}}">
          <a href="Javascript:(function(){kss.show(document.getElementById('summary_description'), true);kss.hide(document.getElementById('show_summary_button'));})()" id="show_summary_button" class="button icon arrowdown">Summary</a>
        </div>
      {{?}}
    {{?}}
  </div>
  {{? it.paginator}}{{= it.paginator }}{{?}}
  <div class="panel paneled_list">
    {{~ it.presentations :presentation_id:index }}
      <a href="#!_/presentations/{{= presentation_id }}">
        <div class="presentation" data-ajax="/presentations/{{= presentation_id }}/heading" id="session_details_presentation_{{= presentation_id }}"></div>
      </a>
    {{~}}
  </div>
</div>
