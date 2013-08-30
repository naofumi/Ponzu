require 'test_helper'

class SubmissionTest < ActiveSupport::TestCase

  def teardown
    I18n.locale = I18n.default_locale
  end

  test "should get title when en: yes, ja: no" do
    s = submissions(:submission_with_en_title_no_jp_title)
    assert_equal s.en_title, s.title
    refute_equal s.jp_title, s.title
  end

  test "should get title when en: no, ja: yes" do
    s = submissions(:submission_no_en_title_with_jp_title)
    refute_equal s.en_title, s.title
    assert_equal s.jp_title, s.title
  end

  test "should get title when en: yes, ja: yes with :ja locale" do
    I18n.locale = :ja
    s = submissions(:submission_with_en_title_with_jp_title)
    refute_equal s.en_title, s.title
    assert_equal s.jp_title, s.title
  end

  test "should get title when en: yes, ja: yes" do
    I18n.locale = :en
    s = submissions(:submission_with_en_title_with_jp_title)
    assert_equal s.en_title, s.title
    refute_equal s.jp_title, s.title
  end

  test "should get abstract when en: yes, ja: no" do
    s = submissions(:submission_with_en_abstract_no_jp_abstract)
    assert_equal s.en_abstract, s.abstract
    refute_equal s.jp_abstract, s.abstract
  end

  test "should persist institutions" do
    institutions = [Institution.new(:en_name => "en_name_1", :jp_name => "jp_name_1"),
                    Institution.new(:en_name => "en_name_2", :jp_name => "jp_name_2")]
    s = submissions(:generic_submission)
    s.institutions = institutions
    s.save!
    s.reload
    refute_equal institutions, s.institutions # different objects
    assert_equal institutions.first.en_name, s.institutions.first.en_name
    assert_equal institutions.first.jp_name, s.institutions.first.jp_name
    assert_equal institutions.last.en_name, s.institutions.last.en_name
    assert_equal institutions.last.jp_name, s.institutions.last.jp_name
  end

  test "should persist keywords" do
    submission = submissions(:generic_submission)
    submission.keywords = ["hello", "kitty"]
    submission.save!
    submission.reload
    assert_equal ["hello", "kitty"], submission.keywords
  end

  test "must refer to a conference" do
    assert_equal conferences(:generic_conference), 
                 sessions(:generic_session).conference
  end

end
