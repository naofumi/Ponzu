# This initializes @timetable and @rooms and @show_date
timetable 

json.show_date @show_date
json.sessions @sessions.map{|s| s.id}
json.rooms @rooms do |room|
  json.id room.id
  json.name room.name
end