require_relative '../like'

class Like::Vote < Like
  attr_accessible :score

  NULL = 0 # We don't allow NULL scores
  EXCELLENT = 1
  UNIQUE = 2
  validates_inclusion_of :score, :in => 0..2
  validate :must_be_less_than_3_for_each_type
  validate :must_not_have_been_voted_for_same_submission

  def description_for_score(score)
    case score
    when NULL
      "null"
    when EXCELLENT
      "Excellent"
    when UNIQUE
      "Unique"
    end
  end

  def must_be_less_than_3_for_each_type
    return if score == 0
    likes_with_same_score = user.votes.find_all_by_score(score)
    # raise "#{(likes_with_same_score - [self])}.inspect"
    if (likes_with_same_score - [self]).count >= 3
      errors.add(:base, "Already voted 3 times for #{description_for_score(score)}.")
    end
  end

  def must_not_have_been_voted_for_same_submission
    return if score == 0
    likes_for_same_submission = user.votes.includes(:presentation).
                                  where("presentations.submission_id" => presentation.submission.id).all
    if !(likes_for_same_submission - [self]).empty?
      errors.add(:base, 
                 "You have already voted for this submission" + 
                 " (#{likes_for_same_submission.map{|l| l.presentation.number}.join(', ')})"
                )
    end
  end
end