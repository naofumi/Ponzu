module LikesHelper
  def vote_class
    if @vote_class.nil?
      @vote_class = begin
        "Like::Vote::#{current_conference.module_name}".constantize
      rescue NameError
        false
      end
    else
      @vote_class
    end
  end
end
