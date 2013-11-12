class Session::Ad < Session
  def path(controller)
    session = self
    controller.instance_eval do
      session_path(session)
    end
  end
end