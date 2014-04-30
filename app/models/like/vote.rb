# Although we don't directly need Like::Like for Like::Vote
# we need it so that a reference to Like::Like, if occurs
# elsewhere in code, will correctly reference Like::Like
# instead of mistakenly referencing ::Like
# http://stackoverflow.com/questions/9807827/preventing-warning-toplevel-constant-b-referenced-by-ab-with-namespaced-cla
require_relative 'like'
require_relative '../like'

class Like::Vote < ::Like
  validate :presentation_must_be_votable

  def presentation_must_be_votable
    unless presentation.votable
      errors.add(:base, "You cannot vote for presentation #{presentation.number}.")
    end
  end
end