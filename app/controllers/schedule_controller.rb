class ScheduleController < ApplicationController
  def index
    raise "I don't think we use this"
    @user = current_user
    @likes = @user.likes
    @schedules = @user.schedules
  end
end
