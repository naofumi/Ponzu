<div class="program orals" data-expiry="{{= it.expiry }}" data-container-ajax="/ponzu_frame" data-container="ponzu_frame" data-title="{{= it.head_title }}" id="session_detail_{{= it.id }}">
  <div class="panel session_header">
    <div class="number">{{= it.number }}</div>
    <div class="time">
      <a href="#!_{{= it.poster_timetable_path }}" onclick="KSScrollMemory.set({href: {{= '/' + it.poster_timetable_path }}, elementId: 'session_{{= it.id }}'})" class="button icon clock">
        {{= it.starts_at }} - {{= it.ends_at }}
      </a>
    </div>
    <div class="room">
      <a href="#!_/rooms/{{= it.room.id }}" class="button icon pin">{{= it.room.name }}</a>
    </div>
    <div class="title">
      {{= it.title }}
    </div>
    {{? it.organizers.length > 0 }}
      <div class="chairs">
        <span class="label">Chairs</span>
        <div>
          {{= it.organizers.join('<br />') }}
        </div>
      </div>
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
