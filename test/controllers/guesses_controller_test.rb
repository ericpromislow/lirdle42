require "test_helper"

class GuessesControllerTest < ActionDispatch::IntegrationTest
  include GuessesHelper

  test "all zeros" do
    score = calculate_score("abcde", "fghij")
    assert_equal [0, 0, 0, 0, 0], score
    assert !is_correct_score(score)
  end

  test "all twos" do
    score = calculate_score("abcde", "abcde")
    assert_equal [2, 2, 2, 2, 2], score
    assert is_correct_score(score)
  end

  test "mixed, no dupes" do
    score = calculate_score("abcde", "cdxye")
    assert_equal [0, 0, 1, 1, 2], score
    assert !is_correct_score(score)
  end

  test "mixed, with dupes" do
    score = calculate_score("clock", "block")
    assert_equal [0, 2, 2, 2, 2], score
    assert !is_correct_score(score)
  end
end
