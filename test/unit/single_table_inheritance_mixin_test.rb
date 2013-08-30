require 'test_helper'

class SingleTableInheritanceMixinTest < ActiveSupport::TestCase
  def setup
    @session = sessions(:generic_session)
    @submission = submissions(:generic_submission)
  end

  def new_presentation(klass)
    klass.new(:submission_id => @submission.id, 
               :session_id => @session.id,
               :starts_at => @session.starts_at)
  end


  def test_presentation_class_should_save_with_type_nil
    presentation = new_presentation(Presentation)
    assert_nil presentation.type
    assert presentation.save
    presentation.reload
    assert_nil presentation.type
  end

  def test_descendant_of_presentation_class_should_save_with_type_set
    presentation = new_presentation(Presentation::Booth)
    assert "Presentation::Booth", presentation.type
    assert presentation.save
    presentation.reload
    assert "Presentation::Booth", presentation.type
  end

  def test_type_is_changeable_within_base_model_descendants
    presentation = new_presentation(Presentation::Booth)
    presentation.type = "Presentation::TimeTableable"
    assert presentation.save
    reloaded_presentation = Presentation::TimeTableable.find(presentation.id)
    assert "Presentation::TimeTableable", reloaded_presentation.type
  end

  def test_erroneous_type_value_should_not_save
    presentation = new_presentation(Presentation::Booth)
    presentation.type = "Presentation::Funky"
    assert "Presentation::Funky", presentation.type
    refute presentation.save
    assert_match presentation.errors[:type].first, /must be a valid subclass of Presentation$/
  end

  def test_model_name
    assert_equal "Presentation", Presentation::Booth.model_name
    assert_equal "Presentation", Presentation::Mappable.model_name
    assert_equal "Presentation", Presentation.model_name
  end
  # test "the truth" do
  #   assert true
  # end
end
