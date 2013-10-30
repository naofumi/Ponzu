# encoding: UTF-8
require 'test_helper'

class PresentationTest < ActiveSupport::TestCase
  def setup
    @presentation = presentations(:generic_presentation)
  end

  test "must refer to a conference" do
    assert_equal conferences(:generic_conference), @presentation.conference
  end

  test "conference_tag must be same as submission" do
    @presentation.submission = submissions(:another_conference_submission)
    e = assert_raises ActiveRecord::RecordInvalid do
      @presentation.save!
    end
  end

  test "conference_tag must be same as session" do
    @presentation.session = sessions(:session_on_different_conference)
    e = assert_raises ActiveRecord::RecordInvalid do
      @presentation.save!
    end    
  end

  test "conference_tag should be reset" do
    @presentation.conference_tag = nil
    assert @presentation.save
    assert_equal conferences(:generic_conference), @presentation.conference
  end

  test "presentation should delegate to submissions" do
    [:en_title, :jp_title, :main_author_id, 
     :disclose_at, :en_abstract, :jp_abstract, :keywords].each do |method|
      assert_equal @presentation.submission.send(method), @presentation.send(method)
    end
  end

  test "presentations should not save unless time within session bounds" do
    skip "Verify how strict we should be on time bounds"
    @session = sessions(:session_on_2011_12_14)
    @submission = submissions(:generic_submission)
    p = @session.presentations.build(:starts_at => Time.parse('2013-01-01 12:00:00'),
                          :ends_at => Time.parse('2013-01-01 13:00:00'), 
                          :submission_id => @submission.id)
    refute p.save
  end

  test "presentation should not save without session" do
    @submission = submissions(:generic_submission)
    p = Presentation.new(:starts_at => Time.parse('2013-01-01 12:00:00'),
                          :ends_at => Time.parse('2013-01-01 13:00:00'), 
                          :submission_id => @submission.id)
    assert_raises ActiveRecord::RecordInvalid do
      p.save!
    end
  end

  test "get next" do
    @presentation = presentations(:second_in_session)
    assert_equal presentations(:last_in_session), @presentation.next
  end

  test "get previous" do
    @presentation = presentations(:second_in_session)
    assert_equal presentations(:first_in_session), @presentation.previous
  end

  test "get previous at edge" do
    @presentation = presentations(:first_in_session)
    assert_equal nil, @presentation.previous
  end

  test "get next at edge" do
    @presentation = presentations(:last_in_session)
    assert_equal nil, @presentation.next
  end

  class EmailTest < ActiveSupport::TestCase
    def setup
      @presentation = presentations(:generic_presentation)
      @liker = users(:generic_user_2)
      @liker.update_attribute(:email, "liker@example.com")
      @presentation.likes.create!(:user_id => @liker.id)
    end

    test "should send mail to likers when changed" do
      skip "We currently aren't eagerly persuing this feature"
      @presentation.update_attributes!(:number => "new presentation number")
      assert_match ActionMailer::Base.deliveries.last.encoded, 
                   /#{@presentation.number} was modified/
      assert_match ActionMailer::Base.deliveries.last.encoded, 
                   /http:\/\/example\.com#!_\/presentations\/#{@presentation.id}/

    end
  end

end



